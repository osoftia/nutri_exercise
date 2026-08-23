/// Pure morph math shared by the nutrition controller and the dynamic avatar
/// painter.
///
/// Maps a consumed/target calorie ratio to a normalized morph factor `t` in
/// `[0, 1]` where `0 = thinnest`, `0.5 = normal build` and `1 = widest`.
///
///   - ratio <= 0.5  -> t = 0.0 (under-eating / very lean)
///   - ratio = 1.0   -> t = 0.5 (on target)
///   - ratio = 1.5   -> t = 1.0 (heavy / over-eating)
///   - ratio outside [0.5, 1.5] is clamped to [0.0, 1.0]
double morphFactorFor(int consumed, int target) {
  if (target <= 0) return 0.5;
  final ratio = consumed / target;
  return ((ratio - 0.5) / 1.0).clamp(0.0, 1.0);
}
