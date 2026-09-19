import '../domain/body_projection/body_segment.dart';
import '../domain/body_projection/muscle_workout_log.dart';
import '../domain/body_projection/nutrition_log.dart';
import '../domain/popups/exercise_completion.dart';

/// Data contract for the blueprint diagram's detail popups.
///
/// Implementations may read SQLite, the mock seed or a local cache; the
/// presentation layer only depends on this interface.
abstract interface class BodyDetailRepository {
  /// Loads today's logged foods.
  Future<DailyFoodLog> loadTodayFoodLog();

  /// Persists today's food log, replacing any previously stored items.
  Future<void> saveTodayFoodLog(DailyFoodLog log);

  /// Loads the planned/completed work for [segment].
  Future<MuscleWorkoutLog> loadWorkoutLog(BodySegment segment);

  /// Loads today's completed exercise records.
  Future<List<CompletedExercise>> loadCompletedExercises();

  /// Persists today's completed exercise records, replacing previous ones.
  Future<void> saveCompletedExercises(List<CompletedExercise> exercises);
}
