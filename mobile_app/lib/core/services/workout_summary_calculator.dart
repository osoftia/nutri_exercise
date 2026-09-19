import '../domain/popups/exercise_completion.dart';
import '../utils/exercise_muscle_mapper.dart';

/// Pure summariser for a confirmed workout.
///
/// It maps each exercise to its activated regions (via [ExerciseMuscleMapper]),
/// aggregates the planned/completed sets per region and derives a
/// [RecoveryLevel], while estimating the calories burned.
class WorkoutSummaryCalculator {
  /// Creates the (stateless) calculator.
  const WorkoutSummaryCalculator();

  /// Estimated calories burned per exercise that had at least one completed set.
  static const int caloriesPerExercise = 250;

  /// Builds the [ExerciseCompletionSummary] for [exercises].
  ExerciseCompletionSummary summarize({
    required String date,
    required List<CompletedExercise> exercises,
  }) {
    final planned = <String, int>{};
    final completed = <String, int>{};

    for (final exercise in exercises) {
      final activation = ExerciseMuscleMapper.activationFor(exercise.name);
      final regions = {
        ...activation.primaryRegions,
        ...activation.secondaryRegions,
      };
      for (final region in regions) {
        planned[region] = (planned[region] ?? 0) + exercise.plannedSets;
        completed[region] =
            (completed[region] ?? 0) + exercise.completedSets;
      }
    }

    final recovery = <String, RecoveryLevel>{
      for (final region in planned.keys)
        region: _level(completed[region] ?? 0, planned[region]!),
    };

    final burned = exercises
            .where((exercise) => exercise.completedSets > 0)
            .length *
        caloriesPerExercise;

    return ExerciseCompletionSummary(
      date: date,
      exercises: exercises,
      caloriesBurned: burned,
      recovery: recovery,
    );
  }

  static RecoveryLevel _level(int done, int total) {
    if (total <= 0 || done <= 0) return RecoveryLevel.fatigued;
    if (done >= total) return RecoveryLevel.recovered;
    return RecoveryLevel.recovering;
  }
}
