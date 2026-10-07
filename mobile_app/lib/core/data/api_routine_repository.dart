import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import '../models/routine_models.dart';
import 'description_parser.dart';
import 'local_routine_repository.dart';
import 'routine_repository.dart';
import '../services/global_error_handler.dart';

/// Thrown when the backend rejects the request for a client-side reason
/// (e.g. HTTP 400) and no fallback should be attempted.
class RoutineApiException implements Exception {
  const RoutineApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Offline-first repository backed by the C# .NET API.
///
/// Every API call degrades seamlessly to [LocalRoutineRepository] (SQLite) on
/// timeout, network error, or server error (5xx), so the app never blocks on
/// an unreachable backend. Successful API generations are also persisted to
/// SQLite so they survive an app restart.
class ApiRoutineRepository implements RoutineRepository {
  ApiRoutineRepository(
    this.baseUrl, {
    RoutineRepository? fallback,
    LocalRoutineRepository? local,
    http.Client? client,
    this.timeout = const Duration(seconds: 10),
  })  : _local = local ?? LocalRoutineRepository(),
        _client = client ?? http.Client() {
    _fallback = fallback ?? _local;
  }

  final String baseUrl;
  final LocalRoutineRepository _local;
  final http.Client _client;
  final Duration timeout;
  late final RoutineRepository _fallback;

  @override
  Future<List<WorkoutDay>> getWeeklyRoutine() async {
    final uri = Uri.parse('$baseUrl${ApiConstants.routinesPath}');
    try {
      final response = await _client.get(uri).timeout(timeout);
      if (response.statusCode != 200) {
        await ErrorHandlerRegistry.capture(
          AppHttpStatusException(
            response.statusCode,
            response.reasonPhrase ?? 'HTTP error',
          ),
          StackTrace.current,
          requestUri: uri,
        );
        return await _fallback.getWeeklyRoutine();
      }
      final data = jsonDecode(response.body);
      if (data is! List<dynamic>) {
        await ErrorHandlerRegistry.capture(
          const FormatException('Expected a JSON routine list.'),
          StackTrace.current,
          requestUri: uri,
        );
        return await _fallback.getWeeklyRoutine();
      }
      return data
          .map((routine) => _mapRoutine(routine as Map<String, dynamic>))
          .toList();
    } catch (error, stackTrace) {
      await ErrorHandlerRegistry.capture(error, stackTrace, requestUri: uri);
      return _fallback.getWeeklyRoutine();
    }
  }

  @override
  Future<String> generateRoutine(String userPreferences) async {
    final uri = Uri.parse('$baseUrl${ApiConstants.generateRoutinePath}');
    try {
      final response = await _client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'userPreferences': userPreferences}),
          )
          .timeout(timeout);

      if (response.statusCode == 400) {
        await ErrorHandlerRegistry.capture(
          const AppHttpStatusException(400, 'Bad Request'),
          StackTrace.current,
          requestUri: uri,
        );
        throw const RoutineApiException(
          'Your preferences were not accepted by the server. '
          'Please review your answers and try again.',
        );
      }
      if (response.statusCode != 200) {
        await ErrorHandlerRegistry.capture(
          AppHttpStatusException(
            response.statusCode,
            response.reasonPhrase ?? 'HTTP error',
          ),
          StackTrace.current,
          requestUri: uri,
        );
        return await _fallback.generateRoutine(userPreferences);
      }

      final body = jsonDecode(response.body);
      if (body is! Map<String, dynamic>) {
        throw const FormatException('Malformed routine payload.');
      }

      final day = _mapRoutine(body);
      await _local.saveRoutine(day);
      return body['description'] as String? ?? '';
    } on RoutineApiException {
      rethrow;
    } catch (error, stackTrace) {
      await ErrorHandlerRegistry.capture(error, stackTrace, requestUri: uri);
      return _fallback.generateRoutine(userPreferences);
    }
  }

  /// Maps the backend `Routine` payload onto the app's [WorkoutDay] model.
  ///
  /// Prefers a structured `exercises` array when present; otherwise falls back
  /// to parsing the free-form `description` text against the exercise catalog.
  WorkoutDay _mapRoutine(Map<String, dynamic> json) {
    final rawExercises = json['exercises'];
    final exercises = rawExercises is List<dynamic>
        ? rawExercises
            .map((e) => Exercise.fromJson(e as Map<String, dynamic>))
            .toList()
        : parseDescriptionToExercises(json['description'] as String? ?? '');
    return WorkoutDay(
      id: json['id'] as int,
      weekday: json['dayOfWeek'] as String,
      focus: json['name'] as String,
      exercises: exercises,
    );
  }
}
