import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nutri_mobile_app/core/data/ai_diagnosis_repository.dart';
import 'package:nutri_mobile_app/core/data/ai_diagnosis_store.dart';
import 'package:nutri_mobile_app/core/data/error_log_repository.dart';
import 'package:nutri_mobile_app/core/domain/clinical/clinical_condition.dart';
import 'package:nutri_mobile_app/core/domain/clinical/clinical_condition_profile.dart';
import 'package:nutri_mobile_app/core/models/ai_diagnosis.dart';
import 'package:nutri_mobile_app/core/models/error_log_entry.dart';
import 'package:nutri_mobile_app/core/services/global_error_handler.dart';

class _MemoryStore implements AiDiagnosisStore {
  AiDiagnosisReport? report;
  String preferences = '';

  @override
  Future<List<AiDiagnosisReport>> all() async =>
      report == null ? [] : [report!];

  @override
  Future<AiDiagnosisReport?> latest() async => report;

  @override
  Future<String> loadFoodPreferences() async => preferences;

  @override
  Future<void> save(AiDiagnosisReport value) async => report = value;

  @override
  Future<void> saveFoodPreferences(String value) async => preferences = value;
}

class _MemoryErrorLogRepository implements ErrorLogRepository {
  final List<ErrorLogEntry> entries = [];

  @override
  Future<List<ErrorLogEntry>> getAll() async => entries;

  @override
  Future<void> record(ErrorLogEntry entry) async => entries.add(entry);
}

void main() {
  const profile = ClinicalConditionProfile(
    conditions: {
      ClinicalCondition.diabetes: ClinicalSeverity.moderate,
      ClinicalCondition.highCholesterol: ClinicalSeverity.high,
    },
  );
  const responseBody = {
    'title': 'Personalized nutrition report',
    'summary': 'A balanced, fiber-rich pattern may be appropriate.',
    'considerations': ['Review nutrition changes with your clinician.'],
    'menus': [
      {
        'name': 'Monday',
        'day': 'Monday',
        'meals': [
          {'name': 'Oats with berries'},
          'Lentil and vegetable bowl',
        ],
      },
    ],
  };

  test('matches Swagger payload keys and types for diagnosis generation',
      () async {
    final store = _MemoryStore();
    late http.Request captured;
    final repository = AiDiagnosisRepository(
      'https://api.example.test',
      store: store,
      client: MockClient((request) async {
        captured = request;
        return http.Response(jsonEncode(responseBody), 200);
      }),
    );

    final report = await repository.generateDiagnosis(
      profile: profile,
      foodPreferences: '  Vegetarian; dislikes mushrooms  ',
      language: 'es',
    );

    expect(captured.url.path, '/api/clinical/diagnosis');
    expect(captured.headers['content-type'], contains('application/json'));
    final payload = jsonDecode(captured.body) as Map<String, dynamic>;
    expect(payload.keys.toSet(), {'preferences', 'conditions', 'userId'});
    expect(payload['preferences'], 'Vegetarian; dislikes mushrooms');
    expect(
      payload['conditions'],
      'diabetes:moderate,highCholesterol:high',
    );
    expect(payload['userId'], 1);
    expect(payload['preferences'], isA<String>());
    expect(payload['conditions'], isA<String>());
    expect(payload['userId'], isA<int>());
    expect(report.conditionIds, ['diabetes', 'highCholesterol']);
    expect(report.menus.single.meals, hasLength(2));
    expect(store.report, same(report));
    expect(store.preferences, 'Vegetarian; dislikes mushrooms');
  });

  test('does not issue a request when no active conditions are selected',
      () async {
    var requested = false;
    final repository = AiDiagnosisRepository(
      'https://api.example.test',
      store: _MemoryStore(),
      client: MockClient((_) async {
        requested = true;
        return http.Response('', 200);
      }),
    );

    await expectLater(
      repository.generateDiagnosis(
        profile: const ClinicalConditionProfile(),
        foodPreferences: '',
        language: 'en',
      ),
      throwsA(isA<AiDiagnosisException>()),
    );
    expect(requested, isFalse);
  });

  test('logs the exact serialized Swagger request body after an HTTP failure',
      () async {
    final errorLogs = _MemoryErrorLogRepository();
    ErrorHandlerRegistry.current = GlobalErrorHandler(
      repository: errorLogs,
      showAlert: (_) {},
    );
    addTearDown(() => ErrorHandlerRegistry.current = null);
    final repository = AiDiagnosisRepository(
      'https://api.example.test',
      store: _MemoryStore(),
      client: MockClient((_) async =>
          http.Response('bad request', 400, reasonPhrase: 'Bad Request')),
    );
    final expectedPayload = {
      'preferences': 'Vegetarian; dislikes mushrooms',
      'conditions': 'diabetes:moderate,highCholesterol:high',
      'userId': 1,
    };

    await expectLater(
      repository.generateDiagnosis(
        profile: profile,
        foodPreferences: ' Vegetarian; dislikes mushrooms ',
        language: 'es',
      ),
      throwsA(isA<AiDiagnosisException>()),
    );

    expect(errorLogs.entries, hasLength(1));
    expect(errorLogs.entries.single.requestUrl,
        'https://api.example.test/api/clinical/diagnosis');
    expect(errorLogs.entries.single.requestBody, jsonEncode(expectedPayload));
  });

  test('keeps the cached report when the service returns invalid data',
      () async {
    final store = _MemoryStore()
      ..report = AiDiagnosisReport.fromJson(
        responseBody,
        conditionIds: const ['diabetes'],
        foodPreferences: '',
        language: 'en',
      );
    final existing = store.report;
    final repository = AiDiagnosisRepository(
      'https://api.example.test',
      store: store,
      client: MockClient((_) async => http.Response('{broken', 200)),
    );

    await expectLater(
      repository.generateDiagnosis(
        profile: profile,
        foodPreferences: '',
        language: 'en',
      ),
      throwsA(isA<AiDiagnosisException>()),
    );
    expect(store.report, same(existing));
  });
}
