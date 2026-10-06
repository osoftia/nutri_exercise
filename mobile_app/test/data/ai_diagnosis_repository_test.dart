import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nutri_mobile_app/core/data/ai_diagnosis_repository.dart';
import 'package:nutri_mobile_app/core/data/ai_diagnosis_store.dart';
import 'package:nutri_mobile_app/core/domain/clinical/clinical_condition.dart';
import 'package:nutri_mobile_app/core/domain/clinical/clinical_condition_profile.dart';
import 'package:nutri_mobile_app/core/models/ai_diagnosis.dart';

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

  test('sends active conditions, severity, preferences, and language',
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
    expect(jsonDecode(captured.body), {
      'conditions': [
        {'id': 'diabetes', 'severity': 'moderate'},
        {'id': 'highCholesterol', 'severity': 'high'},
      ],
      'foodPreferences': 'Vegetarian; dislikes mushrooms',
      'language': 'es',
    });
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
