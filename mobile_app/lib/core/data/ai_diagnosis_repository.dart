import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/clinical/clinical_condition_profile.dart';
import '../models/ai_diagnosis.dart';
import '../models/ai_diagnosis_request.dart';
import '../models/success_log_entry.dart';
import 'ai_diagnosis_store.dart';
import 'success_log_repository.dart';
import '../services/global_error_handler.dart';
import '../services/http_timeout_configuration.dart';

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
    Duration? timeout,
    SuccessLogRepository? successLogRepository,
    DateTime Function()? clock,
  })  : _store = store,
        _client = client ?? http.Client(),
        _timeoutOverride = timeout,
        _successLogRepository = successLogRepository,
        _clock = clock ?? DateTime.now;

  /// The label stored with every successful forensic record.
  static const String successLogLabel = 'clinical_diagnosis';

  final String baseUrl;
  final AiDiagnosisStore _store;
  final http.Client _client;
  final Duration? _timeoutOverride;
  final SuccessLogRepository? _successLogRepository;
  final DateTime Function() _clock;
  Duration get timeout =>
      _timeoutOverride ?? HttpTimeoutConfiguration.currentTimeout;

  Future<AiDiagnosisReport> generateDiagnosis({
    required ClinicalConditionProfile profile,
    required String foodPreferences,
    required String language,
    int userId = 1,
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
      userId: userId,
    );
    await _store.saveFoodPreferences(foodPreferences.trim());
    final requestBody = jsonEncode(request.toJson());
    final uri = Uri.parse('$baseUrl$endpointPath');
    var responseBody = '';
    try {
      final response = await _client
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: requestBody,
          )
          .timeout(timeout);
      responseBody = response.body;
      if (response.statusCode < 200 || response.statusCode >= 300) {
        await ErrorHandlerRegistry.capture(
          AppHttpStatusException(
            response.statusCode,
            response.reasonPhrase ?? 'HTTP error',
          ),
          StackTrace.current,
          requestUri: uri,
          requestBody: requestBody,
          responseBody: responseBody,
        );
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
        conditionIds:
            profile.conditions.keys.map((value) => value.name).toList(),
        foodPreferences: foodPreferences.trim(),
        language: language,
        responseJson: response.body,
      );
      await _store.save(report);
      await _recordSuccess(
        uri: uri,
        statusCode: response.statusCode,
        requestBody: requestBody,
        responseBody: responseBody,
      );
      return report;
    } on AiDiagnosisException {
      rethrow;
    } on FormatException catch (error, stackTrace) {
      await ErrorHandlerRegistry.capture(
        error,
        stackTrace,
        requestUri: uri,
        requestBody: requestBody,
        responseBody: responseBody,
      );
      throw AiDiagnosisException(
          'The clinical report response was invalid: $error');
    } on TimeoutException catch (error, stackTrace) {
      await ErrorHandlerRegistry.capture(
        error,
        stackTrace,
        requestUri: uri,
        requestBody: requestBody,
        responseBody: responseBody,
      );
      throw const AiDiagnosisException(
        'The clinical report service timed out. Your saved reports are still available.',
      );
    } catch (error, stackTrace) {
      await ErrorHandlerRegistry.capture(
        error,
        stackTrace,
        requestUri: uri,
        requestBody: requestBody,
        responseBody: responseBody,
      );
      throw AiDiagnosisException(
        'Could not reach the clinical report service. Your saved reports are still available. ($error)',
      );
    }
  }

  /// Persists the raw successful exchange for local diagnostics.
  ///
  /// Success forensics are best-effort: a storage failure must never discard a
  /// report the user already generated.
  Future<void> _recordSuccess({
    required Uri uri,
    required int statusCode,
    required String requestBody,
    required String responseBody,
  }) async {
    final repository = _successLogRepository;
    if (repository == null) return;
    try {
      await repository.record(
        SuccessLogEntry(
          timestamp: _clock().toUtc(),
          statusCode: statusCode.toString(),
          label: successLogLabel,
          requestUrl: uri.toString(),
          requestBody: requestBody,
          responseBody: responseBody,
        ),
      );
    } catch (_) {
      // Forensic storage must not mask a successful diagnosis.
    }
  }

  Future<AiDiagnosisReport?> latestDiagnosis() => _store.latest();

  Future<List<AiDiagnosisReport>> diagnosisHistory() => _store.all();

  Future<String> loadFoodPreferences() => _store.loadFoodPreferences();

  Future<void> saveFoodPreferences(String preferences) =>
      _store.saveFoodPreferences(preferences);
}
