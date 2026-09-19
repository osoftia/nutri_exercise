import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/body_detail_repository.dart';
import '../domain/body_projection/body_diagram_builder.dart';
import '../domain/body_projection/body_diagram_view_model.dart';
import '../domain/body_projection/body_projection_forecaster.dart';
import '../domain/body_projection/body_segment.dart';
import '../domain/body_projection/callout_layout_table.dart';
import '../domain/body_projection/muscle_gap_advisor.dart';
import '../domain/body_projection/muscle_workout_log.dart';
import '../domain/body_projection/nutrition_log.dart';
import '../domain/notifications/exercise_check_in.dart';
import '../domain/popups/exercise_completion.dart';
import '../models/food_entry.dart';
import '../services/rule_based_body_projection_forecaster.dart';
import '../services/tamagotchi_scale_mapper.dart';
import 'muscle_tamagotchi_state.dart';

/// ChangeNotifier backing the blueprint diagram and its detail popups.
///
/// It loads today's food log and the per-segment workout logs for the overview,
/// exposes the resolved model for the popups and asks the [MuscleGapAdvisor]
/// for a suggestion when a muscle group is opened.
class BodyDetailController extends ChangeNotifier {
  /// Creates a controller.
  BodyDetailController({
    required BodyDetailRepository repository,
    required MuscleGapAdvisor advisor,
    BodyProjectionForecaster? forecaster,
    MuscleTamagotchiState? tamagotchi,
    int calorieTarget = 2000,
    MacroTargets macroTargets = MacroTargets.daily,
  })  : _repository = repository,
        _advisor = advisor,
        _forecaster = forecaster ?? const RuleBasedBodyProjectionForecaster(),
        _tamagotchi = tamagotchi,
        _calorieTarget = calorieTarget,
        _macroTargets = macroTargets {
    _tamagotchi?.addListener(_onTamagotchiChanged);
  }

  final BodyDetailRepository _repository;
  final MuscleGapAdvisor _advisor;
  final BodyProjectionForecaster _forecaster;
  final MuscleTamagotchiState? _tamagotchi;

  /// The segments the overview assembles statuses for (the callout segments).
  static final List<BodySegment> overviewSegments = {
    for (final slot in bodyCalloutSlots) slot.segment,
  }.toList(growable: false);

  DailyFoodLog _foodLog = const DailyFoodLog();
  Map<BodySegment, MuscleWorkoutLog> _workouts = const {};
  bool _isLoadingOverview = false;
  String? _overviewError;

  bool _isLoadingFood = false;
  String? _foodError;

  MuscleWorkoutLog? _workoutLog;
  bool _isLoadingWorkout = false;
  String? _workoutError;

  String? _suggestion;
  bool _isLoadingSuggestion = false;

  BodyProjectionForecast? _forecast;
  bool _isLoadingForecast = false;
  String? _forecastError;
  ({int month, double shoulder, double waist})? _projectionParams;

  int _quickFoodCursor = 0;

  int _calorieTarget;
  MacroTargets _macroTargets;

  /// Daily calorie target used by the abdomen status.
  int get calorieTarget => _calorieTarget;

  /// Daily macro targets used by the abdomen status.
  MacroTargets get macroTargets => _macroTargets;

  /// Today's food log.
  DailyFoodLog get foodLog => _foodLog;

  /// Cached workout logs for the overview segments.
  Map<BodySegment, MuscleWorkoutLog> get workouts => _workouts;

  /// Whether the overview is loading.
  bool get isLoadingOverview => _isLoadingOverview;

  /// Overview loading error, if any.
  String? get overviewError => _overviewError;

  /// Whether the food log is loading.
  bool get isLoadingFood => _isLoadingFood;

  /// Food log loading error, if any.
  String? get foodError => _foodError;

  /// The workout log most recently opened, if any.
  MuscleWorkoutLog? get workoutLog => _workoutLog;

  /// Whether the workout log is loading.
  bool get isLoadingWorkout => _isLoadingWorkout;

  /// Workout loading error, if any.
  String? get workoutError => _workoutError;

  /// The AI suggestion for the most recently opened muscle group.
  String? get suggestion => _suggestion;

  /// Whether the AI suggestion is loading.
  bool get isLoadingSuggestion => _isLoadingSuggestion;

  /// The latest projection forecast, if a projection has been applied.
  BodyProjectionForecast? get forecast => _forecast;

  /// Whether a projection forecast is loading.
  bool get isLoadingForecast => _isLoadingForecast;

  /// Projection forecast error, if any.
  String? get forecastError => _forecastError;

  /// Updates the calorie and macro targets used for the abdomen status.
  void setNutritionTargets({int? calorieTarget, MacroTargets? macroTargets}) {
    _calorieTarget = calorieTarget ?? _calorieTarget;
    _macroTargets = macroTargets ?? _macroTargets;
    notifyListeners();
  }

  /// Quick-add presets appended by the food sheet's "Add food" action.
  static const List<LoggedFood> quickFoods = [
    LoggedFood(
      name: 'Protein Shake',
      portion: '1 scoop',
      calories: 150,
      proteinG: 30,
      carbsG: 6,
      fatG: 1,
      time: '18:00',
    ),
    LoggedFood(
      name: 'Banana',
      portion: '1 medium',
      calories: 105,
      proteinG: 1,
      carbsG: 27,
      fatG: 0,
      time: '18:05',
    ),
    LoggedFood(
      name: 'Almonds',
      portion: '30 g',
      calories: 170,
      proteinG: 6,
      carbsG: 6,
      fatG: 15,
      time: '18:10',
    ),
  ];

  /// Loads the overview (food + every callout segment) and notifies.
  ///
  /// When a projection is already active it is re-forecast against the freshly
  /// loaded logs so the diagram never shows a stale projection.
  Future<void> loadOverview() async {
    _isLoadingOverview = true;
    _overviewError = null;
    notifyListeners();
    try {
      _foodLog = await _repository.loadTodayFoodLog();
      final workouts = <BodySegment, MuscleWorkoutLog>{};
      for (final segment in overviewSegments) {
        workouts[segment] = await _repository.loadWorkoutLog(segment);
      }
      _workouts = workouts;
    } catch (_) {
      _overviewError = 'Could not load your body blueprint.';
    }
    _isLoadingOverview = false;
    notifyListeners();
    if (_projectionParams != null) {
      await _runForecast();
    }
  }

  /// Applies the selected milestone by asking the [BodyProjectionForecaster].
  Future<void> applyProjection({
    required int month,
    required double shoulderFactor,
    required double waistFactor,
  }) async {
    _projectionParams = (
      month: month,
      shoulder: shoulderFactor,
      waist: waistFactor,
    );
    await _runForecast();
  }

  Future<void> _runForecast() async {
    final params = _projectionParams;
    if (params == null) return;

    _isLoadingForecast = true;
    _forecastError = null;
    notifyListeners();
    try {
      _forecast = await _forecaster.forecast(
        ProjectionForecastRequest(
          month: params.month,
          shoulderFactor: params.shoulder,
          waistFactor: params.waist,
          foodLog: _foodLog,
          workouts: _workouts,
          calorieTarget: _calorieTarget,
          macroTargets: _macroTargets,
        ),
      );
    } catch (_) {
      _forecastError = 'Could not project your body.';
    }
    _isLoadingForecast = false;
    notifyListeners();
  }

  /// Builds the immutable view model for the diagram.
  ///
  /// Tamagotchi muscle mass / core fullness drive the baseline per-segment
  /// thickness; an active projection multiplies on top of it. When a
  /// [forecast] (or the latest applied projection) exists, its estimated
  /// statuses replace the current-log-derived ones.
  BodyDiagramViewModel buildViewModel({
    BodySegment? selectedSegment,
    BodyProjectionForecast? forecast,
  }) {
    final tamagotchi = _tamagotchi;
    final tamagotchiScales = tamagotchi == null
        ? const <BodySegment, double>{}
        : tamagotchiScaleFactors(
            mass: tamagotchi.massOf,
            coreFullness: tamagotchi.coreFullness,
          );

    final base = const BodyDiagramBuilder().build(
      foodLog: _foodLog,
      workouts: _workouts,
      calorieTarget: _calorieTarget,
      macroTargets: _macroTargets,
      scaleFactors: tamagotchiScales,
      selectedSegment: selectedSegment,
    );

    final projection = forecast ?? _forecast;
    if (projection == null) return base;

    return base.copyWith(
      scaleFactors: {
        for (final segment in BodySegment.values)
          segment:
              projection.scaleFor(segment) * (tamagotchiScales[segment] ?? 1.0),
      },
      statuses: projection.statuses,
    );
  }

  void _onTamagotchiChanged() => notifyListeners();

  @override
  void dispose() {
    _tamagotchi?.removeListener(_onTamagotchiChanged);
    super.dispose();
  }

  /// Loads today's food log for the food sheet and notifies.
  Future<void> loadFoodLog() async {
    _isLoadingFood = true;
    _foodError = null;
    notifyListeners();
    try {
      _foodLog = await _repository.loadTodayFoodLog();
    } catch (_) {
      _foodError = 'Could not load today\'s food.';
    }
    _isLoadingFood = false;
    notifyListeners();
  }

  /// Appends the next [quickFoods] preset and notifies listeners.
  void addQuickFood() {
    final food = quickFoods[_quickFoodCursor % quickFoods.length];
    _quickFoodCursor++;
    unawaited(addFood(food));
  }

  /// Appends [food] to today's log, persists it and notifies listeners.
  ///
  /// When a Tamagotchi is attached, its core bloats by the food's calories so
  /// the avatar reacts instantly.
  Future<void> addFood(LoggedFood food) async {
    _foodLog = _foodLog.copyWith(entries: [..._foodLog.entries, food]);
    _tamagotchi?.applyNutrition(food.calories);
    notifyListeners();
    await _repository.saveTodayFoodLog(_foodLog);
  }

  /// Removes the food at [index], persists the log and notifies listeners.
  ///
  /// When a Tamagotchi is attached, its core is slimmed in proportion to the
  /// removed calories so the avatar reacts instantly.
  Future<void> removeFood(int index) async {
    if (index < 0 || index >= _foodLog.entries.length) return;
    final removed = _foodLog.entries[index];
    final remaining = [..._foodLog.entries]..removeAt(index);
    _foodLog = _foodLog.copyWith(entries: remaining);
    _tamagotchi?.applySlimming(amount: removed.calories / 2000);
    notifyListeners();
    await _repository.saveTodayFoodLog(_foodLog);
  }

  /// The planned exercises of the overview, marked as fully completed.
  ///
  /// Used by the manual check-in to propose a workout to confirm. Actual
  /// completed records are read via [completedExercises].
  List<CompletedExercise> plannedExercises() => [
        for (final workout in _workouts.values)
          for (final entry in workout.entries)
            CompletedExercise(
              name: entry.name,
              plannedSets: entry.plannedSets,
              completedSets: entry.plannedSets,
              reps: entry.reps,
              loadKg: entry.loadKg,
            ),
      ];

  /// Reads today's persisted completed exercises from the repository.
  Future<List<CompletedExercise>> completedExercises() =>
      _repository.loadCompletedExercises();

  /// Encodes the planned exercises into a notification check-in payload.
  ///
  /// Used to schedule the 9 PM reminder with full sets/reps/load parity.
  String exerciseCheckInPayload() =>
      ExerciseCheckIn(exercises: plannedExercises()).encode();

  /// Loads the workout log for [segment] plus its AI suggestion and notifies.
  Future<void> loadWorkout(BodySegment segment) async {
    _isLoadingWorkout = true;
    _workoutError = null;
    _suggestion = null;
    _workoutLog = null;
    notifyListeners();

    try {
      final log = _workouts[segment] ??
          await _repository.loadWorkoutLog(segment);
      _workoutLog = log;
      _isLoadingWorkout = false;
      _isLoadingSuggestion = true;
      notifyListeners();

      _suggestion = await _advisor.advise(
        MuscleGapContext(segment: segment, workout: log),
      );
    } catch (_) {
      _workoutError = 'Could not load this muscle group.';
      _workoutLog = null;
    }

    _isLoadingWorkout = false;
    _isLoadingSuggestion = false;
    notifyListeners();
  }
}
