import '../data/body_detail_repository.dart';
import '../data/body_detail_seed.dart';
import '../domain/body_projection/body_segment.dart';
import '../domain/body_projection/muscle_workout_log.dart';
import '../domain/body_projection/nutrition_log.dart';
import '../domain/popups/exercise_completion.dart';

/// Deterministic, in-memory [BodyDetailRepository] used by the dev flavor and
/// by tests (which can inject their own food log and workout map).
class MockBodyDetailRepository implements BodyDetailRepository {
  /// Creates a mock repository, falling back to the shared seed.
  MockBodyDetailRepository({
    DailyFoodLog? foodLog,
    Map<BodySegment, MuscleWorkoutLog>? workouts,
    List<CompletedExercise>? completedExercises,
  })  : _foodLog = foodLog ?? bodyFoodLogSeed,
        _workouts = workouts ?? bodyDetailPlannedSeed,
        _completed = completedExercises ?? const [];

  DailyFoodLog _foodLog;
  final Map<BodySegment, MuscleWorkoutLog> _workouts;
  List<CompletedExercise> _completed;

  @override
  Future<DailyFoodLog> loadTodayFoodLog() async => _foodLog;

  @override
  Future<void> saveTodayFoodLog(DailyFoodLog log) async => _foodLog = log;

  @override
  Future<MuscleWorkoutLog> loadWorkoutLog(BodySegment segment) async {
    final base = _workouts[segment] ??
        MuscleWorkoutLog(segment: segment, periodLabel: 'This week');
    return _overlay(base);
  }

  @override
  Future<List<CompletedExercise>> loadCompletedExercises() async => _completed;

  @override
  Future<void> saveCompletedExercises(List<CompletedExercise> exercises) async {
    _completed = List<CompletedExercise>.unmodifiable(exercises);
  }

  /// Replaces the completed sets of planned entries with any persisted record.
  MuscleWorkoutLog _overlay(MuscleWorkoutLog base) {
    if (_completed.isEmpty || base.isEmpty) return base;
    final byName = {for (final c in _completed) c.name: c};
    return base.copyWith(
      entries: [
        for (final entry in base.entries)
          byName.containsKey(entry.name)
              ? entry.copyWith(completedSets: byName[entry.name]!.completedSets)
              : entry,
      ],
    );
  }
}
