import '../../models/food_entry.dart';
import 'body_diagram_view_model.dart';
import 'body_segment.dart';
import 'callout_layout_table.dart';
import 'macro_balance.dart';
import 'muscle_workout_log.dart';
import 'nutrition_log.dart';
import 'segment_balance.dart';
import 'segment_balance_calculator.dart';
import 'segment_balance_input.dart';

/// Pure use case that assembles a [BodyDiagramViewModel] from the day's food
/// log, the per-segment workout logs and the selected projection scales.
///
/// This is the only place that turns logged data into statuses and callout
/// text, so widgets and painters stay free of business logic.
class BodyDiagramBuilder {
  /// Creates a builder using [calculator] for the segment statuses.
  const BodyDiagramBuilder({this.calculator = const SegmentBalanceCalculator()});

  /// The status calculator.
  final SegmentBalanceCalculator calculator;

  /// Builds the view model.
  ///
  /// [calorieTarget] and [macroTargets] come from the user's plan.
  BodyDiagramViewModel build({
    required DailyFoodLog foodLog,
    required Map<BodySegment, MuscleWorkoutLog> workouts,
    required int calorieTarget,
    required MacroTargets macroTargets,
    Map<BodySegment, double> scaleFactors = const {},
    BodySegment? selectedSegment,
  }) {
    final balances = balancesFor(
      foodLog: foodLog,
      workouts: workouts,
      calorieTarget: calorieTarget,
      macroTargets: macroTargets,
    );
    final statuses = {
      for (final entry in balances.entries) entry.key: entry.value.status,
    };
    final callouts = [
      for (final slot in bodyCalloutSlots)
        _calloutFor(slot.segment, foodLog, workouts),
    ];

    return BodyDiagramViewModel(
      statuses: statuses,
      scaleFactors: scaleFactors,
      callouts: callouts,
      selectedSegment: selectedSegment,
    );
  }

  /// Computes the current [SegmentBalance] of every callout segment.
  ///
  /// Exposed so projection forecasters can damp the raw imbalance scores
  /// without re-deriving the training/nutrition inputs.
  Map<BodySegment, SegmentBalance> balancesFor({
    required DailyFoodLog foodLog,
    required Map<BodySegment, MuscleWorkoutLog> workouts,
    required int calorieTarget,
    required MacroTargets macroTargets,
  }) {
    return {
      for (final slot in bodyCalloutSlots)
        slot.segment: calculator.compute(
          _inputFor(
            segment: slot.segment,
            foodLog: foodLog,
            workouts: workouts,
            calorieTarget: calorieTarget,
            macroTargets: macroTargets,
          ),
        ),
    };
  }

  SegmentBalanceInput _inputFor({
    required BodySegment segment,
    required DailyFoodLog foodLog,
    required Map<BodySegment, MuscleWorkoutLog> workouts,
    required int calorieTarget,
    required MacroTargets macroTargets,
  }) {
    if (segment.isAbdomen) {
      if (foodLog.isEmpty) return SegmentBalanceInput(segment: segment);
      return SegmentBalanceInput(
        segment: segment,
        calorieBalance: (foodLog.totalCalories - calorieTarget).toDouble(),
        macroBalance: MacroBalance(
          proteinDeltaG: (foodLog.totalProteinG - macroTargets.protein).toDouble(),
          carbsDeltaG: (foodLog.totalCarbsG - macroTargets.carbs).toDouble(),
          fatDeltaG: (foodLog.totalFatG - macroTargets.fat).toDouble(),
        ),
      );
    }

    final workout = workouts[segment];
    if (workout == null || workout.isEmpty) {
      return SegmentBalanceInput(segment: segment);
    }
    return SegmentBalanceInput(
      segment: segment,
      trainedVolume: workout.completedVolume,
      targetVolume: workout.plannedVolume,
    );
  }

  BodyCallout _calloutFor(
    BodySegment segment,
    DailyFoodLog foodLog,
    Map<BodySegment, MuscleWorkoutLog> workouts,
  ) {
    if (segment.isAbdomen) {
      return BodyCallout(
        segment: segment,
        label: 'STOMACH',
        value: '${foodLog.totalCalories} kcal',
      );
    }
    final workout = workouts[segment];
    return BodyCallout(
      segment: segment,
      label: _calloutLabels[segment] ?? segment.name.toUpperCase(),
      value: '${workout?.completedSets ?? 0}/${workout?.plannedSets ?? 0} sets',
    );
  }
}

const Map<BodySegment, String> _calloutLabels = {
  BodySegment.chest: 'CHEST',
  BodySegment.leftUpperArm: 'ARM L',
  BodySegment.rightUpperArm: 'ARM R',
  BodySegment.leftForearm: 'ARM L',
  BodySegment.rightForearm: 'ARM R',
  BodySegment.leftThigh: 'LEG L',
  BodySegment.rightThigh: 'LEG R',
  BodySegment.leftCalf: 'CALF L',
  BodySegment.rightCalf: 'CALF R',
  BodySegment.abdomen: 'STOMACH',
};
