import 'body_segment.dart';

/// A planned exercise and how much of it the user has completed.
class MuscleExerciseLog {
  /// Creates an exercise log.
  const MuscleExerciseLog({
    required this.name,
    required this.plannedSets,
    required this.reps,
    required this.loadKg,
    required this.completedSets,
  });

  /// Exercise name (e.g. `Squat`).
  final String name;

  /// Sets prescribed by the plan.
  final int plannedSets;

  /// Repetitions per set.
  final int reps;

  /// Load per repetition in kilograms.
  final double loadKg;

  /// Sets actually completed.
  final int completedSets;

  /// Planned training volume (`sets × reps × load`).
  double get plannedVolume => plannedSets * reps * loadKg;

  /// Completed training volume (`sets × reps × load`).
  double get completedVolume => completedSets * reps * loadKg;

  /// Sets still to do, never negative.
  int get remainingSets => (plannedSets - completedSets).clamp(0, plannedSets);

  /// Whether the planned sets were reached.
  bool get isCompleted => completedSets >= plannedSets;

  /// Returns a copy with the provided fields replaced.
  MuscleExerciseLog copyWith({
    String? name,
    int? plannedSets,
    int? reps,
    double? loadKg,
    int? completedSets,
  }) {
    return MuscleExerciseLog(
      name: name ?? this.name,
      plannedSets: plannedSets ?? this.plannedSets,
      reps: reps ?? this.reps,
      loadKg: loadKg ?? this.loadKg,
      completedSets: completedSets ?? this.completedSets,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is MuscleExerciseLog &&
      other.name == name &&
      other.plannedSets == plannedSets &&
      other.reps == reps &&
      other.loadKg == loadKg &&
      other.completedSets == completedSets;

  @override
  int get hashCode =>
      Object.hash(name, plannedSets, reps, loadKg, completedSets);

  @override
  String toString() =>
      'MuscleExerciseLog($name, $completedSets/$plannedSets sets)';
}

/// Immutable snapshot of a muscle group's planned and completed work.
class MuscleWorkoutLog {
  /// Creates a workout log for [segment] covering [periodLabel].
  const MuscleWorkoutLog({
    required this.segment,
    required this.periodLabel,
    this.entries = const [],
  });

  /// The body segment this log belongs to.
  final BodySegment segment;

  /// Human-readable period (e.g. `Today`, `This week`).
  final String periodLabel;

  /// The exercises planned and performed for the period.
  final List<MuscleExerciseLog> entries;

  /// Whether nothing is planned.
  bool get isEmpty => entries.isEmpty;

  /// Summed planned volume of every exercise.
  double get plannedVolume => _sum((e) => e.plannedVolume);

  /// Summed completed volume of every exercise.
  double get completedVolume => _sum((e) => e.completedVolume);

  /// Summed planned sets.
  int get plannedSets => _sumInt((e) => e.plannedSets);

  /// Summed completed sets.
  int get completedSets => _sumInt((e) => e.completedSets);

  /// Completed volume as a `0..1` fraction of the planned volume.
  double get completionRatio =>
      plannedVolume <= 0 ? 1 : (completedVolume / plannedVolume).clamp(0, 1);

  double _sum(double Function(MuscleExerciseLog e) pick) {
    var total = 0.0;
    for (final entry in entries) {
      total += pick(entry);
    }
    return total;
  }

  int _sumInt(int Function(MuscleExerciseLog e) pick) {
    var total = 0;
    for (final entry in entries) {
      total += pick(entry);
    }
    return total;
  }

  /// Returns a copy with the provided fields replaced.
  MuscleWorkoutLog copyWith({
    BodySegment? segment,
    String? periodLabel,
    List<MuscleExerciseLog>? entries,
  }) {
    return MuscleWorkoutLog(
      segment: segment ?? this.segment,
      periodLabel: periodLabel ?? this.periodLabel,
      entries: entries ?? this.entries,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is MuscleWorkoutLog &&
      other.segment == segment &&
      other.periodLabel == periodLabel &&
      _listEquals(other.entries, entries);

  @override
  int get hashCode => Object.hash(segment, periodLabel, Object.hashAll(entries));

  @override
  String toString() =>
      'MuscleWorkoutLog(${segment.name}, ${entries.length} entries)';
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
