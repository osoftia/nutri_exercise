/// Pure value objects for the post-workout completion summary popup.
library;

/// One confirmed exercise and how much of it was completed.
class CompletedExercise {
  /// Creates a completed exercise line.
  const CompletedExercise({
    required this.name,
    required this.plannedSets,
    required this.completedSets,
    required this.reps,
    required this.loadKg,
  });

  /// Exercise name (e.g. `Bench Press`).
  final String name;

  /// Sets prescribed by the plan.
  final int plannedSets;

  /// Sets actually completed.
  final int completedSets;

  /// Repetitions per set.
  final int reps;

  /// Load per repetition in kilograms.
  final double loadKg;

  /// Whether every planned set was completed.
  bool get isComplete => completedSets >= plannedSets;

  /// Sets still to do, never negative.
  int get remainingSets => (plannedSets - completedSets).clamp(0, plannedSets);

  /// Completed training volume (`sets × reps × load`).
  double get volume => completedSets * reps * loadKg;

  /// Returns a copy with the provided fields replaced.
  CompletedExercise copyWith({
    String? name,
    int? plannedSets,
    int? completedSets,
    int? reps,
    double? loadKg,
  }) {
    return CompletedExercise(
      name: name ?? this.name,
      plannedSets: plannedSets ?? this.plannedSets,
      completedSets: completedSets ?? this.completedSets,
      reps: reps ?? this.reps,
      loadKg: loadKg ?? this.loadKg,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is CompletedExercise &&
      other.name == name &&
      other.plannedSets == plannedSets &&
      other.completedSets == completedSets &&
      other.reps == reps &&
      other.loadKg == loadKg;

  @override
  int get hashCode =>
      Object.hash(name, plannedSets, completedSets, reps, loadKg);

  @override
  String toString() =>
      'CompletedExercise($name, $completedSets/$plannedSets sets)';
}

/// How recovered a muscle region is after a workout.
enum RecoveryLevel {
  /// Every planned set was completed.
  recovered,

  /// Some, but not all, planned sets were completed.
  recovering,

  /// The region was planned but nothing was completed.
  fatigued,
}

/// Immutable summary shown after a workout is confirmed.
class ExerciseCompletionSummary {
  /// Creates a completion summary.
  const ExerciseCompletionSummary({
    required this.date,
    required this.exercises,
    required this.caloriesBurned,
    this.recovery = const {},
  });

  /// The reference day (`YYYY-MM-DD`).
  final String date;

  /// The confirmed exercises.
  final List<CompletedExercise> exercises;

  /// Estimated calories burned.
  final int caloriesBurned;

  /// Per-region recovery levels keyed by region id (`chest`, `thighs`, ...).
  final Map<String, RecoveryLevel> recovery;

  /// Whether nothing was completed.
  bool get isEmpty => exercises.isEmpty;

  /// Summed completed sets.
  int get totalSets => _sum((e) => e.completedSets);

  /// Summed completed repetitions (`sets × reps`).
  int get totalReps => _sum((e) => e.completedSets * e.reps);

  /// Summed completed volume.
  double get totalVolume => _sumDouble((e) => e.volume);

  int _sum(int Function(CompletedExercise e) pick) {
    var total = 0;
    for (final exercise in exercises) {
      total += pick(exercise);
    }
    return total;
  }

  double _sumDouble(double Function(CompletedExercise e) pick) {
    var total = 0.0;
    for (final exercise in exercises) {
      total += pick(exercise);
    }
    return total;
  }

  /// Returns a copy with the provided fields replaced.
  ExerciseCompletionSummary copyWith({
    String? date,
    List<CompletedExercise>? exercises,
    int? caloriesBurned,
    Map<String, RecoveryLevel>? recovery,
  }) {
    return ExerciseCompletionSummary(
      date: date ?? this.date,
      exercises: exercises ?? this.exercises,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      recovery: recovery ?? this.recovery,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ExerciseCompletionSummary &&
      other.date == date &&
      _listEquals(other.exercises, exercises) &&
      other.caloriesBurned == caloriesBurned &&
      _mapEquals(other.recovery, recovery);

  @override
  int get hashCode =>
      Object.hash(date, Object.hashAll(exercises), caloriesBurned, _mapHash(recovery));

  @override
  String toString() =>
      'ExerciseCompletionSummary($date, ${exercises.length} exercises, '
      '$caloriesBurned kcal)';
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

bool _mapEquals<K, V>(Map<K, V> a, Map<K, V> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (final entry in a.entries) {
    if (!b.containsKey(entry.key) || b[entry.key] != entry.value) return false;
  }
  return true;
}

int _mapHash<K, V>(Map<K, V> map) =>
    Object.hashAllUnordered(map.entries.map((e) => Object.hash(e.key, e.value)));
