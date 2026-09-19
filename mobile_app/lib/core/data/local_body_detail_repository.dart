import '../database/database_helper.dart';
import '../domain/body_projection/body_segment.dart';
import '../domain/body_projection/muscle_workout_log.dart';
import '../domain/body_projection/nutrition_log.dart';
import '../domain/popups/exercise_completion.dart';
import '../models/daily_entry.dart';
import 'body_detail_repository.dart';
import 'body_detail_seed.dart';

/// SQLite-backed [BodyDetailRepository].
///
/// Food logs and completed exercises are stored per day in `food_logs` and
/// `exercise_completions`; planned workouts come from [bodyDetailPlannedSeed]
/// and are overlaid with the persisted completions.
class LocalBodyDetailRepository implements BodyDetailRepository {
  /// Creates a local repository.
  ///
  /// [dateKey] resolves the reference day and is injectable so tests stay
  /// deterministic without touching the wall clock.
  LocalBodyDetailRepository({
    DatabaseHelper? databaseHelper,
    String Function()? dateKey,
    Map<BodySegment, MuscleWorkoutLog> plannedWorkouts =
        bodyDetailPlannedSeed,
  })  : _databaseHelper = databaseHelper ?? DatabaseHelper(),
        _dateKey = dateKey ?? (() => DailyEntry.dateKey(DateTime.now())),
        _plannedWorkouts = plannedWorkouts;

  final DatabaseHelper _databaseHelper;
  final String Function() _dateKey;
  final Map<BodySegment, MuscleWorkoutLog> _plannedWorkouts;

  @override
  Future<DailyFoodLog> loadTodayFoodLog() async {
    final date = _dateKey();
    final rows = await _databaseHelper.getFoodLogsByDate(date);
    return DailyFoodLog(
      date: date,
      entries: rows.map(_foodFromRow).toList(growable: false),
    );
  }

  @override
  Future<void> saveTodayFoodLog(DailyFoodLog log) {
    return _databaseHelper.replaceFoodLogsByDate(
      _dateKey(),
      [for (final food in log.entries) _foodToRow(food)],
    );
  }

  @override
  Future<MuscleWorkoutLog> loadWorkoutLog(BodySegment segment) async {
    final base = _plannedWorkouts[segment] ??
        MuscleWorkoutLog(segment: segment, periodLabel: 'This week');
    final completed = await loadCompletedExercises();
    if (completed.isEmpty || base.isEmpty) return base;

    final byName = {for (final c in completed) c.name: c};
    return base.copyWith(
      entries: [
        for (final entry in base.entries)
          byName.containsKey(entry.name)
              ? entry.copyWith(completedSets: byName[entry.name]!.completedSets)
              : entry,
      ],
    );
  }

  @override
  Future<List<CompletedExercise>> loadCompletedExercises() async {
    final rows = await _databaseHelper.getExerciseCompletionsByDate(_dateKey());
    return rows.map(_completionFromRow).toList(growable: false);
  }

  @override
  Future<void> saveCompletedExercises(List<CompletedExercise> exercises) {
    return _databaseHelper.replaceExerciseCompletionsByDate(
      _dateKey(),
      [for (final exercise in exercises) _completionToRow(exercise)],
    );
  }

  Map<String, Object?> _foodToRow(LoggedFood food) => {
        'date': _dateKey(),
        'name': food.name,
        'portion': food.portion,
        'calories': food.calories,
        'protein': food.proteinG,
        'carbs': food.carbsG,
        'fat': food.fatG,
        'time': food.time,
        'created_at': DateTime.now().toIso8601String(),
      };

  LoggedFood _foodFromRow(Map<String, Object?> row) => LoggedFood(
        name: row['name'] as String,
        portion: row['portion'] as String,
        calories: (row['calories'] as num).toInt(),
        proteinG: (row['protein'] as num).toInt(),
        carbsG: (row['carbs'] as num).toInt(),
        fatG: (row['fat'] as num).toInt(),
        time: row['time'] as String,
      );

  Map<String, Object?> _completionToRow(CompletedExercise exercise) => {
        'date': _dateKey(),
        'name': exercise.name,
        'planned_sets': exercise.plannedSets,
        'completed_sets': exercise.completedSets,
        'reps': exercise.reps,
        'load_kg': exercise.loadKg,
        'created_at': DateTime.now().toIso8601String(),
      };

  CompletedExercise _completionFromRow(Map<String, Object?> row) =>
      CompletedExercise(
        name: row['name'] as String,
        plannedSets: (row['planned_sets'] as num).toInt(),
        completedSets: (row['completed_sets'] as num).toInt(),
        reps: (row['reps'] as num).toInt(),
        loadKg: (row['load_kg'] as num).toDouble(),
      );
}
