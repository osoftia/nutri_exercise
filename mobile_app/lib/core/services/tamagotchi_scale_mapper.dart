import '../domain/body_projection/body_segment.dart';
import '../state/muscle_tamagotchi_state.dart';

/// Maps the gamified [MuscleTamagotchiState] metrics onto per-segment
/// thickness multipliers for the blueprint figure.
///
/// A neutral group mass (`0.5`) and zero core fullness map to `0.75`; a fully
/// grown group (`1.0`) maps to `1.25`, so the figure visibly hypertrophies and
/// the abdomen visibly bloats.
Map<BodySegment, double> tamagotchiScaleFactors({
  required double Function(MuscleTamagotchiGroup group) mass,
  required double coreFullness,
}) {
  double limb(MuscleTamagotchiGroup group) =>
      0.75 + 0.5 * mass(group).clamp(0.0, 1.0);

  final arm = limb(MuscleTamagotchiGroup.arms);
  final chest = limb(MuscleTamagotchiGroup.chest);
  final leg = limb(MuscleTamagotchiGroup.legs);
  final abdomen = 0.75 + 0.5 * coreFullness.clamp(0.0, 1.0);

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
