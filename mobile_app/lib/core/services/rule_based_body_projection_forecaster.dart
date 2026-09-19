import '../domain/body_projection/body_diagram_builder.dart';
import '../domain/body_projection/body_projection_forecaster.dart';
import '../domain/body_projection/body_segment.dart';
import '../domain/body_projection/segment_balance_calculator.dart';

/// Deterministic, fully local [BodyProjectionForecaster].
///
/// It maps the milestone's morph factors onto per-segment thickness and damps
/// the current logged imbalance toward balanced as the projected month grows,
/// so later milestones read as "the plan is being followed". No model is ever
/// loaded, which keeps it offline-safe and cheap to run in tests.
class RuleBasedBodyProjectionForecaster implements BodyProjectionForecaster {
  /// Creates the forecaster.
  const RuleBasedBodyProjectionForecaster({
    this.builder = const BodyDiagramBuilder(),
    this.calculator = const SegmentBalanceCalculator(),
  });

  /// Reused to derive the current per-segment balances.
  final BodyDiagramBuilder builder;

  /// Reused to map damped scores back to statuses.
  final SegmentBalanceCalculator calculator;

  /// Fraction of an imbalance recovered per projected month.
  static const double monthlyRecovery = 0.2;

  @override
  Future<BodyProjectionForecast> forecast(
    ProjectionForecastRequest request,
  ) async {
    final balances = builder.balancesFor(
      foodLog: request.foodLog,
      workouts: request.workouts,
      calorieTarget: request.calorieTarget,
      macroTargets: request.macroTargets,
    );
    final decay = 1 / (1 + request.month * monthlyRecovery);
    final statuses = {
      for (final entry in balances.entries)
        entry.key: calculator.statusForScore(entry.value.imbalanceScore * decay),
    };

    return BodyProjectionForecast(
      month: request.month,
      scaleFactors: scaleFactorsFor(
        shoulderFactor: request.shoulderFactor,
        waistFactor: request.waistFactor,
      ),
      statuses: statuses,
    );
  }

  /// Pure mapping from the projection morph factors to per-segment thickness.
  ///
  /// Baseline factors (`0.5`) produce a scale of `1.0`.
  static Map<BodySegment, double> scaleFactorsFor({
    required double shoulderFactor,
    required double waistFactor,
  }) {
    final arm = 0.8 + 0.4 * shoulderFactor;
    final chest = 0.7 + 0.6 * shoulderFactor;
    final abdomen = 0.7 + 0.6 * waistFactor;
    final leg = 0.85 + 0.3 * waistFactor;
    return {
      BodySegment.chest: chest,
      BodySegment.abdomen: abdomen,
      BodySegment.leftUpperArm: arm,
      BodySegment.rightUpperArm: arm,
      BodySegment.leftForearm: arm,
      BodySegment.rightForearm: arm,
      BodySegment.leftThigh: leg,
      BodySegment.rightThigh: leg,
      BodySegment.leftCalf: leg,
      BodySegment.rightCalf: leg,
    };
  }
}
