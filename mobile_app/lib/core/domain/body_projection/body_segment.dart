/// Which signal primarily determines a [BodySegment]'s balance.
enum SegmentDriver {
  /// Driven by performed `trainedVolume` versus the plan's `targetVolume`.
  training,

  /// Driven by `calorieBalance` (and the macro deltas as a secondary nudge).
  calorie,
}

/// The independently addressable anatomical segments of the blueprint diagram.
///
/// Arms and legs are intentionally split into an upper and a lower segment so
/// the painter can render a visible elbow / knee joint gap and so every part is
/// its own hit target. Coordinates are *not* part of the domain: the painter
/// owns geometry, this enum only owns anatomy and balance semantics.
enum BodySegment {
  head,
  neck,
  chest,
  abdomen,
  leftUpperArm,
  leftForearm,
  rightUpperArm,
  rightForearm,
  leftThigh,
  leftCalf,
  rightThigh,
  rightCalf;

  /// The signal that primarily drives this segment's imbalance score.
  SegmentDriver get driver =>
      isAbdomen ? SegmentDriver.calorie : SegmentDriver.training;

  /// Whether this segment is the calorie-driven abdominal region.
  bool get isAbdomen => this == BodySegment.abdomen;
}
