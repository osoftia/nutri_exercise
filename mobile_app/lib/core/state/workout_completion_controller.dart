import 'package:flutter/foundation.dart';

import '../constants/tamagotchi_groups.dart';
import '../data/body_detail_repository.dart';
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
  })  : _calculator = calculator,
        _tamagotchi = tamagotchi,
        _repository = repository;

  final WorkoutSummaryCalculator _calculator;
  final MuscleTamagotchiState? _tamagotchi;
  final BodyDetailRepository? _repository;

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

    _isConfirming = false;
    notifyListeners();
  }

  /// Reverses the confirmation: clears the stored completions, shrinks the
  /// grown muscles and restores the slimmed core.
  Future<void> undo() async {
    if (!_isConfirmed) return;

    await _repository?.saveCompletedExercises(const []);

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
