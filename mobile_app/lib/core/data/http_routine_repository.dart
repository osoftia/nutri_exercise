import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/routine_models.dart';
import 'routine_repository.dart';

class HttpRoutineRepository implements RoutineRepository {
  HttpRoutineRepository(this.baseUrl);

  final String baseUrl;

  @override
  Future<List<WorkoutDay>> getWeeklyRoutine() async {
    final response = await http.get(Uri.parse('$baseUrl/api/v1/routines/week'));
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((day) => WorkoutDay.fromJson(day as Map<String, dynamic>))
        .toList();
  }
}
