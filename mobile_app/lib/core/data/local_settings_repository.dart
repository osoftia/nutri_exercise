import 'dart:convert';

import '../database/database_helper.dart';
import '../models/routine_models.dart';
import 'settings_repository.dart';

/// SQLite-backed [SettingsRepository] for managing saved routine records.
class LocalSettingsRepository implements SettingsRepository {
  LocalSettingsRepository({DatabaseHelper? databaseHelper})
    : _databaseHelper = databaseHelper ?? DatabaseHelper();

  final DatabaseHelper _databaseHelper;

  @override
  Future<List<WorkoutDay>> getRecords() async {
    final rows = await _databaseHelper.getRoutines();
    return rows.map(_fromRow).toList();
  }

  @override
  Future<void> updateRecordFocus(int id, String focus) async {
    final rows = await _databaseHelper.getRoutines();
    final index = rows.indexWhere((r) => r['id'] == id);
    if (index < 0) return;
    final row = rows[index];
    final day = _fromRow(row);
    await _databaseHelper.upsertRoutine(
      WorkoutDay(
        id: day.id,
        weekday: day.weekday,
        focus: focus,
        exercises: day.exercises,
      ),
    );
  }

  @override
  Future<void> deleteRecord(int id) async {
    await _databaseHelper.deleteRoutine(id);
  }

  WorkoutDay _fromRow(Map<String, Object?> row) {
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
  }
}
