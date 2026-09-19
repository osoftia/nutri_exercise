import 'body_segment.dart';
import 'macro_balance.dart';

/// Immutable input for a single segment's balance computation.
///
/// Domain code never calls `DateTime.now()`: the caller resolves the reference
/// day first and passes the resulting volumes and balances explicitly, which
/// keeps the calculation pure and its tests deterministic.
class SegmentBalanceInput {
  /// Creates a balance input for [segment].
  const SegmentBalanceInput({
    required this.segment,
    this.trainedVolume = 0,
    this.targetVolume = 0,
    this.calorieBalance = 0,
    this.macroBalance = MacroBalance.none,
  });

  /// The segment being evaluated.
  final BodySegment segment;

  /// Performed volume (`sets × reps × load`) for the segment's muscle groups.
  final double trainedVolume;

  /// The plan's target volume for the same period.
  final double targetVolume;

  /// `consumed kcal − (BMR + activity expenditure)`.
  final double calorieBalance;

  /// Protein / carb / fat deltas versus the day's targets.
  final MacroBalance macroBalance;

  /// Whether any signal is available for the reference day.
  ///
  /// An all-zero input means nothing was logged, which maps to
  /// `SegmentStatus.noData` rather than to a false "balanced".
  bool get hasAnyData =>
      trainedVolume != 0 ||
      targetVolume != 0 ||
      calorieBalance != 0 ||
      macroBalance.hasAnyDelta;

  /// Returns a copy of this input with the provided fields replaced.
  SegmentBalanceInput copyWith({
    BodySegment? segment,
    double? trainedVolume,
    double? targetVolume,
    double? calorieBalance,
    MacroBalance? macroBalance,
  }) {
    return SegmentBalanceInput(
      segment: segment ?? this.segment,
      trainedVolume: trainedVolume ?? this.trainedVolume,
      targetVolume: targetVolume ?? this.targetVolume,
      calorieBalance: calorieBalance ?? this.calorieBalance,
      macroBalance: macroBalance ?? this.macroBalance,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is SegmentBalanceInput &&
      other.segment == segment &&
      other.trainedVolume == trainedVolume &&
      other.targetVolume == targetVolume &&
      other.calorieBalance == calorieBalance &&
      other.macroBalance == macroBalance;

  @override
  int get hashCode => Object.hash(
        segment,
        trainedVolume,
        targetVolume,
        calorieBalance,
        macroBalance,
      );

  @override
  String toString() =>
      'SegmentBalanceInput(segment: ${segment.name}, '
      'trainedVolume: $trainedVolume, targetVolume: $targetVolume, '
      'calorieBalance: $calorieBalance, macroBalance: $macroBalance)';
}
