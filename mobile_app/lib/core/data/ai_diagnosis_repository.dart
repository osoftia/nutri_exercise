import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/clinical/clinical_condition_profile.dart';
import '../models/ai_diagnosis.dart';
import '../models/ai_diagnosis_request.dart';
import 'ai_diagnosis_store.dart';

/// Failure returned when a new report cannot be safely generated.
class AiDiagnosisException implements Exception {
  const AiDiagnosisException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Client/server bridge for report generation with SQLite-backed history.
///
/// Network and parsing failures leave previously persisted reports untouched;
/// callers can continue to display [latestDiagnosis] while offline.
class AiDiagnosisRepository {
  static const String endpointPath = '/api/clinical/diagnosis';

  AiDiagnosisRepository(
    this.baseUrl, {
    required AiDiagnosisStore store,
    http.Client? client,
    this.timeout = const Duration(seconds: 20),
  })  : _store = store,
        _client = client ?? http.Client();

  final String baseUrl;
  final AiDiagnosisStore _store;
  final http.Client _client;
  final Duration timeout;

  Future<AiDiagnosisReport> generateDiagnosis({
    required ClinicalConditionProfile profile,
    required String foodPreferences,
    required String language,
  }) async {
    if (profile.isEmpty) {
      throw const AiDiagnosisException(
        'Select at least one active condition before generating a report.',
      );
    }
    final request = AiDiagnosisRequest.fromProfile(
      profile: profile,
      foodPreferences: foodPreferences,
      language: language,
    );
    await _store.saveFoodPreferences(request.foodPreferences);
    final uri = Uri.parse('$baseUrl$endpointPath');
    try {
      final response = await _client
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(request.toJson()),
          )
          .timeout(timeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AiDiagnosisException(
          'The clinical report service returned ${response.statusCode}.',
        );
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Expected a JSON report object.');
      }
      final report = AiDiagnosisReport.fromJson(
        decoded,
        conditionIds: request.conditions.map((item) => item['id']!).toList(),
        foodPreferences: request.foodPreferences,
        language: request.language,
      );
      await _store.save(report);
      return report;
    } on AiDiagnosisException {
      rethrow;
    } on FormatException catch (error) {
      throw AiDiagnosisException(
          'The clinical report response was invalid: $error');
    } on TimeoutException {
      throw const AiDiagnosisException(
        'The clinical report service timed out. Your saved reports are still available.',
      );
    } catch (error) {
      throw AiDiagnosisException(
        'Could not reach the clinical report service. Your saved reports are still available. ($error)',
      );
    }
  }

  Future<AiDiagnosisReport?> latestDiagnosis() => _store.latest();

  Future<List<AiDiagnosisReport>> diagnosisHistory() => _store.all();

  Future<String> loadFoodPreferences() => _store.loadFoodPreferences();

  Future<void> saveFoodPreferences(String preferences) =>
      _store.saveFoodPreferences(preferences);
}
