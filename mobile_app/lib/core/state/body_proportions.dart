import 'dart:math' as math;

/// Body Mass Index: weight (kg) over height (m) squared.
double bmi(double heightCm, double weightKg) =>
    weightKg / math.pow(heightCm / 100, 2);

/// Maps a BMI to the avatar's baseline body width factor.
///
/// A normal BMI (~22) maps to `1.0`; slimmer bodies are narrower (`< 1.0`) and
/// heavier bodies are wider (`> 1.0`). The factor is clamped to a sane range so
/// extreme inputs never distort the avatar.
double widthFactorForBmi(double bmiValue) {
  const double k = 0.03;
  const double neutral = 22.0;
  final factor = 1.0 + k * (bmiValue - neutral);
  return factor.clamp(0.75, 1.45);
}
