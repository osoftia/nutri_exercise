import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import '../models/routine_models.dart';
import 'routine_repository.dart';

class HttpRoutineRepository implements RoutineRepository {
  HttpRoutineRepository(this.baseUrl, {RoutineRepository? fallback})
    : _fallback = fallback;

  final String baseUrl;
  final RoutineRepository? _fallback;

  static const Duration _timeout = Duration(seconds: 10);

  @override
  Future<List<WorkoutDay>> getWeeklyRoutine() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl${ApiConstants.routinesPath}'))
          .timeout(_timeout);
      if (response.statusCode != 200) {
        throw http.ClientException(
          'Unexpected status code ${response.statusCode}',
          Uri.parse('$baseUrl${ApiConstants.routinesPath}'),
        );
      }
      final data = jsonDecode(response.body) as List<dynamic>;
      return data
          .map((routine) => _fromBackendRoutine(routine as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return _fallback?.getWeeklyRoutine() ?? <WorkoutDay>[];
    }
  }

  @override
  Future<String> generateRoutine(String userPreferences) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl${ApiConstants.generateRoutinePath}'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'userPreferences': userPreferences}),
          )
          .timeout(_timeout);
      if (response.statusCode != 200) {
        throw http.ClientException(
          'Unexpected status code ${response.statusCode}',
          Uri.parse('$baseUrl${ApiConstants.generateRoutinePath}'),
        );
      }
      final routine = jsonDecode(response.body) as Map<String, dynamic>;
      return routine['description'] as String? ?? '';
    } catch (_) {
      if (_fallback != null) return _fallback.generateRoutine(userPreferences);
      rethrow;
    }
  }

  /// Maps the backend `Routine` payload (id, name, dayOfWeek, description)
  /// onto the app's [WorkoutDay] model.
  WorkoutDay _fromBackendRoutine(Map<String, dynamic> json) {
    return WorkoutDay(
      id: json['id'] as int,
      weekday: json['dayOfWeek'] as String,
      focus: json['name'] as String,
      exercises: const <Exercise>[],
    );
  }
}
