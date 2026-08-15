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
    final days = <WorkoutDay>[];
    for (final row in rows) {
      final id = row['id'] as int;
      final exerciseRows = await _databaseHelper.getExercisesForRoutine(id);
      final exercises = <Exercise>[];
      for (final exRow in exerciseRows) {
        final exId = exRow['id'] as int;
        exercises.add(Exercise(
          id: exId,
          name: exRow['name'] as String,
          muscleGroup: exRow['muscle_group'] as String,
          sets: exRow['sets'] as int,
          reps: exRow['reps'] as String,
          restSeconds: exRow['rest_seconds'] as int,
          weight: exRow['weight'] as String?,
        ));
      }
      days.add(WorkoutDay(
        id: id,
        weekday: row['weekday'] as String,
        focus: row['focus'] as String,
        exercises: exercises,
      ));
    }
    return days;
  }

  Future<void> saveRoutine(WorkoutDay day) async {
    await _seedIfNeeded();
    await _databaseHelper.saveWorkoutDay(day);
  }

  @override
  Future<String> generateRoutine(String userPreferences) async {
    await _seedIfNeeded();

    final goal = _extractGoal(userPreferences);
    final days = _extractDays(userPreferences);
    final level = _extractLevel(userPreferences);

    final exercises = _selectExercises(goal, days, level);
    final day = WorkoutDay(
      id: DateTime.now().millisecondsSinceEpoch,
      weekday: 'Weekly',
      focus: _focusLabel(goal),
      exercises: exercises,
    );
    await _databaseHelper.saveWorkoutDay(day, isGenerated: true);

    return 'Offline AI routine for: $userPreferences\n\n'
        'Generated locally from the exercise library. '
        '${exercises.length} exercises saved to your dashboard.';
  }

  Future<void> deleteRoutine(int id) async {
    await _databaseHelper.deleteRoutine(id);
  }

  Future<void> clearAll() async {
    await _databaseHelper.clearAll();
    _seeded = false;
  }

  Future<void> _seedIfNeeded() async {
    if (_seeded) return;
    final rows = await _databaseHelper.getRoutines();
    if (rows.isEmpty) {
      for (final day in mockWorkoutRoutines) {
        await _databaseHelper.saveWorkoutDay(day);
      }
    }
    _seeded = true;
  }

  String _extractGoal(String prefs) {
    final match = RegExp(r'Goal:\s*(\w+)').firstMatch(prefs);
    return match?.group(1) ?? 'build_muscle';
  }

  int _extractDays(String prefs) {
    final match = RegExp(r'Days:\s*(\d+)').firstMatch(prefs);
    return int.tryParse(match?.group(1) ?? '') ?? 4;
  }

  String _extractLevel(String prefs) {
    final match = RegExp(r'Level:\s*(\w+)').firstMatch(prefs);
    return match?.group(1) ?? 'intermediate';
  }

  String _focusLabel(String goal) => switch (goal) {
    'lose_weight' => 'Fat Loss Routine',
    'build_muscle' => 'Muscle Building Routine',
    'maintain' => 'Maintenance Routine',
    'endurance' => 'Endurance Routine',
    _ => 'AI Generated Routine',
  };

  List<Exercise> _selectExercises(String goal, int days, String level) {
    final library = <Exercise>[];
    for (final day in mockWorkoutRoutines) {
      for (final ex in day.exercises) {
        if (!library.any((e) => e.name == ex.name)) library.add(ex);
      }
    }
    final setMultiplier = switch (level) {
      'beginner' => 3,
      'advanced' => 5,
      _ => 4,
    };
    final count = days.clamp(2, 6).toInt();
    final selected = library.take(count * 2).toList();
    return selected
        .map((ex) => Exercise(
              id: ex.id,
              name: ex.name,
              muscleGroup: ex.muscleGroup,
              sets: setMultiplier,
              reps: ex.reps,
              restSeconds: ex.restSeconds,
              weight: ex.weight,
            ))
        .toList();
  }
}