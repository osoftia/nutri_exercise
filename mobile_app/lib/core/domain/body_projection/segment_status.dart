/// The four states a body segment can be rendered in.
///
/// The mapping from an imbalance score to a status is owned by
/// `SegmentBalanceCalculator`; this enum only names the visual states.
enum SegmentStatus {
  /// On target (`|imbalanceScore| <= balancedThreshold`).
  balanced,

  /// Mild imbalance (`balancedThreshold < |score| <= warningThreshold`).
  warning,

  /// Strong imbalance (`|score| > warningThreshold`).
  critical,

  /// Not enough data logged for the reference day.
  noData,
}
