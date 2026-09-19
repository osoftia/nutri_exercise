import 'body_segment.dart';
import 'muscle_workout_log.dart';

/// Context handed to the local AI when advising how to close a training gap.
class MuscleGapContext {
  /// Creates a gap context for [segment] from its [workout] log.
  const MuscleGapContext({required this.segment, required this.workout});

  /// The muscle group being advised on.
  final BodySegment segment;

  /// The planned/completed work for the period.
  final MuscleWorkoutLog workout;

  /// Planned training volume for the period.
  double get plannedVolume => workout.plannedVolume;

  /// Completed training volume for the period.
  double get completedVolume => workout.completedVolume;

  /// Volume still missing to reach the plan (never negative).
  double get volumeGap =>
      (plannedVolume - completedVolume).clamp(0, double.infinity);

  /// Completed volume as a `0..1` fraction of the plan.
  double get completionRatio => workout.completionRatio;

  /// Sets still to do across every exercise in the period.
  int get remainingSets =>
      (workout.plannedSets - workout.completedSets).clamp(0, workout.plannedSets);
}

/// Abstract local-AI advisor for closing a muscle group's training gap.
///
/// Keeping this behind an interface lets the UI stay decoupled from the model
/// and lets tests inject a deterministic fake without ever loading a model.
abstract interface class MuscleGapAdvisor {
  /// Returns a short coaching suggestion for [context].
  Future<String> advise(MuscleGapContext context);
}
