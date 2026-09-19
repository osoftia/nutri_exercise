/// Signed macro deltas (grams) against the day's plan targets.
///
/// Positive values mean the macro was exceeded, negative values mean it was
/// missed. The object is immutable and value-equal.
class MacroBalance {
  /// Creates a macro balance from the three signed gram deltas.
  const MacroBalance({
    this.proteinDeltaG = 0,
    this.carbsDeltaG = 0,
    this.fatDeltaG = 0,
  });

  /// A neutral balance where every macro hit its target.
  static const MacroBalance none = MacroBalance();

  /// Signed protein delta in grams.
  final double proteinDeltaG;

  /// Signed carbohydrate delta in grams.
  final double carbsDeltaG;

  /// Signed fat delta in grams.
  final double fatDeltaG;

  /// Whether any macro deviates from its target.
  bool get hasAnyDelta =>
      proteinDeltaG != 0 || carbsDeltaG != 0 || fatDeltaG != 0;

  /// The unweighted mean of the three signed deltas, in grams.
  double get averageDeltaG =>
      (proteinDeltaG + carbsDeltaG + fatDeltaG) / 3;

  /// Returns a copy with the provided fields replaced.
  MacroBalance copyWith({
    double? proteinDeltaG,
    double? carbsDeltaG,
    double? fatDeltaG,
  }) {
    return MacroBalance(
      proteinDeltaG: proteinDeltaG ?? this.proteinDeltaG,
      carbsDeltaG: carbsDeltaG ?? this.carbsDeltaG,
      fatDeltaG: fatDeltaG ?? this.fatDeltaG,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is MacroBalance &&
      other.proteinDeltaG == proteinDeltaG &&
      other.carbsDeltaG == carbsDeltaG &&
      other.fatDeltaG == fatDeltaG;

  @override
  int get hashCode => Object.hash(proteinDeltaG, carbsDeltaG, fatDeltaG);

  @override
  String toString() =>
      'MacroBalance(protein: $proteinDeltaG, carbs: $carbsDeltaG, '
      'fat: $fatDeltaG)';
}
