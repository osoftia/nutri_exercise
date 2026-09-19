import 'body_segment.dart';
import 'macro_balance.dart';
import 'segment_balance.dart';
import 'segment_balance_input.dart';
import 'segment_status.dart';

/// Pure, stateless calculator that maps a [SegmentBalanceInput] to a
/// [SegmentBalance].
///
/// The score is signed and lives in `[-1.0, 1.0]`:
///
/// * **training-driven** segments (`driver == training`) use
///   `trainedVolume / targetVolume − 1`, so missing sets go negative and extra
///   work goes positive;
/// * the **abdomen** (`driver == calorie`) uses
///   `calorieBalance / calorieFullScaleKcal`, so an uncovered surplus goes
///   positive;
/// * the macro deltas add a bounded secondary nudge to either driver.
///
/// The thresholds below are the only tuning knobs and are named constants so
/// they can change without touching logic.
class SegmentBalanceCalculator {
  /// Creates the (stateless) calculator.
  const SegmentBalanceCalculator();

  /// `|score|` at or below this is [SegmentStatus.balanced].
  static const double balancedThreshold = 0.15;

  /// `|score|` at or below this is [SegmentStatus.warning]; above it is
  /// [SegmentStatus.critical].
  static const double warningThreshold = 0.40;

  /// Calorie surplus (kcal) that saturates the abdomen score to `1.0`.
  static const double calorieFullScaleKcal = 750;

  /// Mean macro delta (grams) that saturates the macro nudge to `1.0`.
  static const double macroFullScaleG = 150;

  /// How strongly the macro nudge is allowed to move the final score.
  static const double macroWeight = 0.15;

  /// Computes the [SegmentBalance] for [input].
  SegmentBalance compute(SegmentBalanceInput input) {
    if (!input.hasAnyData) {
      return SegmentBalance(
        segment: input.segment,
        status: SegmentStatus.noData,
        imbalanceScore: 0,
      );
    }
    final score = _scoreFor(input).clamp(-1.0, 1.0);
    return SegmentBalance(
      segment: input.segment,
      status: statusForScore(score),
      imbalanceScore: score,
    );
  }

  /// Maps a signed, already-clamped [score] to a [SegmentStatus].
  SegmentStatus statusForScore(double score) {
    final magnitude = score.abs();
    if (magnitude <= balancedThreshold) return SegmentStatus.balanced;
    if (magnitude <= warningThreshold) return SegmentStatus.warning;
    return SegmentStatus.critical;
  }

  double _scoreFor(SegmentBalanceInput input) {
    final macroNudge = macroWeight * _macroScore(input.macroBalance);
    final primary = input.segment.driver == SegmentDriver.calorie
        ? _calorieScore(input.calorieBalance)
        : _trainingScore(input.trainedVolume, input.targetVolume);
    return primary + macroNudge;
  }

  double _trainingScore(double trained, double target) {
    if (target <= 0) return 0;
    return trained / target - 1.0;
  }

  double _calorieScore(double balance) => balance / calorieFullScaleKcal;

  double _macroScore(MacroBalance macro) =>
      macro.averageDeltaG / macroFullScaleG;
}
