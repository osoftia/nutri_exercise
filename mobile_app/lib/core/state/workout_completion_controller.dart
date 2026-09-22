import 'package:flutter/foundation.dart';

import '../constants/tamagotchi_groups.dart';
import '../data/body_detail_repository.dart';
import '../data/daily_entry_repository.dart';
import '../domain/popups/exercise_completion.dart';
import '../models/daily_entry.dart';
import '../services/workout_summary_calculator.dart';
import 'muscle_tamagotchi_state.dart';

/// ChangeNotifier that confirms a workout, builds its
/// [ExerciseCompletionSummary] and applies the recovery to the Tamagotchi.
///
/// [confirm] also persists the completed records through the injected
/// [BodyDetailRepository]; [present] only re-summarises already-persisted
/// records (e.g. after a notification action) without double-writing.
class WorkoutCompletionController extends ChangeNotifier {
  /// Creates a completion controller.
  WorkoutCompletionController({
    WorkoutSummaryCalculator calculator = const WorkoutSummaryCalculator(),
    MuscleTamagotchiState? tamagotchi,
    BodyDetailRepository? repository,
    DailyEntryRepository? dailyEntries,
  })  : _calculator = calculator,
        _tamagotchi = tamagotchi,
        _repository = repository,
        _dailyEntries = dailyEntries;

  final WorkoutSummaryCalculator _calculator;
  final MuscleTamagotchiState? _tamagotchi;
  final BodyDetailRepository? _repository;

  /// Optional calendar/weekly-summary store. When attached, every confirmation
  /// also upserts today's [DailyEntry] (exercise names + burned calories) so the
  /// calendar markers and the Weekly Stats view reflect in-app workouts, not
  /// only the notification check-in path.
  final DailyEntryRepository? _dailyEntries;

  ExerciseCompletionSummary? _summary;
  bool _isConfirming = false;
  bool _isConfirmed = false;
  List<CompletedExercise> _confirmed = const [];

  /// The last confirmed summary, or `null` before the first confirmation.
  ExerciseCompletionSummary? get summary => _summary;

  /// Whether a confirmation is in flight.
  bool get isConfirming => _isConfirming;

  /// Whether the workout is currently confirmed (drives the toggle).
  bool get isConfirmed => _isConfirmed;

  /// Confirms [exercises]: persists them, builds the summary and applies
  /// recovery to the Tamagotchi.
  Future<void> confirm(List<CompletedExercise> exercises) async {
    _isConfirming = true;
    notifyListeners();

    await _repository?.saveCompletedExercises(exercises);
    _summary = _summarize(exercises);
    _confirmed = exercises;
    _isConfirmed = exercises.isNotEmpty;
    _applyRecovery(exercises);
    await _syncDailyEntry(exercises);

    _isConfirming = false;
    notifyListeners();
  }

  /// Reverses the confirmation: clears the stored completions, shrinks the
  /// grown muscles and restores the slimmed core.
  Future<void> undo() async {    if (!_isConfirmed) return;

    await _repository?.saveCompletedExercises(const []);
    await _clearDailyEntry();

    final tamagotchi = _tamagotchi;
    final summary = _summary;
    if (tamagotchi != null && summary != null) {
      final groups = <MuscleTamagotchiGroup>{};
      for (final region in summary.recovery.keys) {
        final group = tamagotchiGroupForRegion(region);
        if (group != null) groups.add(group);
      }
      if (groups.isNotEmpty) tamagotchi.applyShrink(groups);
      tamagotchi.restoreCore(
        MuscleTamagotchiState.slimmingPerExercise * _confirmed.length,
      );
    }

    _isConfirmed = false;
    _confirmed = const [];
    _summary = null;
    notifyListeners();
  }

  /// Builds the summary for already-persisted [exercises] without writing or
  /// mutating the Tamagotchi again.
  void present(List<CompletedExercise> exercises) {
    _summary = _summarize(exercises);
    _confirmed = exercises;
    _isConfirmed = exercises.isNotEmpty;
    notifyListeners();
  }

  /// Removes a single [name] from today's completed exercises.
  ///
  /// Persists the remaining completions and re-syncs today's calendar entry
  /// (exercise names + burned calories) so the Weekly Stats stay accurate.
  /// Returns `true` when an exercise was actually removed.
  Future<bool> removeExercise(String name) async {
    final remaining = [
      for (final exercise in _confirmed)
        if (exercise.name != name) exercise,
    ];
    if (remaining.length == _confirmed.length) return false;

    await _repository?.saveCompletedExercises(remaining);
    _confirmed = remaining;
    _isConfirmed = remaining.isNotEmpty;
    _summary = remaining.isEmpty ? null : _summarize(remaining);
    await _syncDailyEntry(remaining);
    notifyListeners();
    return true;
  }

  /// Rehydrates the toggle from today's persisted completions after a restart.
  ///
  /// Unlike [confirm] it never re-applies growth/slimming: the Tamagotchi is
  /// restored independently from its own persisted mass, so a restart cannot
  /// double-count the workout.
  Future<void> restore() async {
    final repository = _repository;
    if (repository == null) return;
    final exercises = await repository.loadCompletedExercises();
    if (exercises.isEmpty) return;
    present(exercises);
  }

  /// Upserts today's calendar entry with the confirmed exercise names and the
  /// burned calories, preserving any nutrition already recorded for the day.
  Future<void> _syncDailyEntry(List<CompletedExercise> exercises) async {
    final repository = _dailyEntries;
    if (repository == null) return;
    final today = DailyEntry.dateKey(DateTime.now());
    final existing = await repository.getByDate(today);
    await repository.save(
      (existing ?? DailyEntry(date: today)).copyWith(
        exercises: [for (final exercise in exercises) exercise.name],
        burned: _summary?.caloriesBurned ?? 0,
      ),
    );
  }

  /// Clears today's exercise names and burned calories (preserving nutrition)
  /// when a confirmation is reversed.
  Future<void> _clearDailyEntry() async {
    final repository = _dailyEntries;
    if (repository == null) return;
    final today = DailyEntry.dateKey(DateTime.now());
    final existing = await repository.getByDate(today);
    if (existing == null) return;
    await repository.save(existing.copyWith(exercises: const [], burned: 0));
  }

  ExerciseCompletionSummary _summarize(List<CompletedExercise> exercises) {
    return _calculator.summarize(
      date: DailyEntry.dateKey(DateTime.now()),
      exercises: exercises,
    );
  }

  void _applyRecovery(List<CompletedExercise> exercises) {
    final tamagotchi = _tamagotchi;
    final summary = _summary;
    if (tamagotchi == null || summary == null || exercises.isEmpty) return;

    final groups = <MuscleTamagotchiGroup>{};
    for (final region in summary.recovery.keys) {
      final group = tamagotchiGroupForRegion(region);
      if (group != null) groups.add(group);
    }
    if (groups.isNotEmpty) tamagotchi.applyGrowth(groups);
    tamagotchi.applySlimming(
      amount: MuscleTamagotchiState.slimmingPerExercise * exercises.length,
    );
  }
}
