import 'dart:convert';

import '../database/database_helper.dart';
import '../mocks/mock_routine_repository.dart';
import '../models/routine_models.dart';
import 'routine_repository.dart';

class LocalRoutineRepository implements RoutineRepository {
  LocalRoutineRepository({DatabaseHelper? databaseHelper})
    : _databaseHelper = databaseHelper ?? DatabaseHelper();

  final DatabaseHelper _databaseHelper;
  bool _seeded = false;

  @override
  Future<List<WorkoutDay>> getWeeklyRoutine() async {
    await _seedIfNeeded();
    final rows = await _databaseHelper.getRoutines();
    return rows.map((row) {
      return WorkoutDay(
        id: row['id'] as int,
        weekday: row['weekday'] as String,
        focus: row['focus'] as String,
        exercises:
            (jsonDecode(row['exercises_json'] as String) as List<dynamic>)
                .map(
                  (exercise) =>
                      Exercise.fromJson(exercise as Map<String, dynamic>),
                )
                .toList(),
      );
    }).toList();
  }

  Future<void> saveRoutine(WorkoutDay day) async {
    await _seedIfNeeded();
    await _databaseHelper.upsertRoutine(day);
  }

  Future<void> _seedIfNeeded() async {
    if (_seeded) return;
    final rows = await _databaseHelper.getRoutines();
    if (rows.isEmpty) {
      for (final day in mockWorkoutRoutines) {
        await _databaseHelper.upsertRoutine(day);
      }
    }
    _seeded = true;
  }
}
