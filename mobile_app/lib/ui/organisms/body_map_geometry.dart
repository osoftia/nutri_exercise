import 'package:flutter/material.dart';

import '../../core/state/muscle_tamagotchi_state.dart';

/// Pure geometry and small decision helpers for the interactive body map.
///
/// Extracted from `interactive_body_map.dart` so the widget file stays focused
/// on rendering and the math stays independently testable (M48 decomposition).

/// Padding factor applied around the figure inside its canvas.
const double kPadFactor = 0.03;

/// Canvas aspect ratio (width / height) of the figure.
const double kAspectRatio = 1.6;

/// How much a full mass delta scales a region.
const double kMassScale = 0.5;

/// Duration of the selection glow cycle.
const Duration kGlowDuration = Duration(milliseconds: 300);

/// Duration of the core bloat animation.
const Duration kBloatDuration = Duration(milliseconds: 700);

/// Overshoot applied while the core bloats.
const double kBloatOvershoot = 0.35;

/// The red tint applied to the Core region while it is bloating.
const Color kCoreBloatColor = Color(0xFFEF4444);

/// Bright-red debug flash painted on the stomach (`abs`) for
/// [MuscleTamagotchiState.foodFlashDuration] after every food log.
const Color kFoodFlashColor = Color(0xFFFF0000);

/// Size factor applied to a muscle region for a given mass.
///
/// A mass equal to the baseline renders at `1.0` (no change); a full `1.0`
/// bulges larger and a `0.0` shrinks.
double scaleForMass(double mass) =>
    1.0 + kMassScale * (mass - MuscleTamagotchiState.baseline);

/// Scales [path] uniformly around its own bounding-box centre.
Path scaleNormalizedPath(Path path, double scale) {
  if (scale == 1.0) return path;
  final bounds = path.getBounds();
  final cx = bounds.center.dx;
  final cy = bounds.center.dy;
  return path.transform(
    (Matrix4.identity()
          // ignore: deprecated_member_use
          ..translate(cx, cy, 0.0)
          // ignore: deprecated_member_use
          ..scale(scale, scale, 1.0)
          // ignore: deprecated_member_use
          ..translate(-cx, -cy, 0.0))
        .storage,
  );
}

/// Stretches [path] horizontally around its centre (non-uniform scale).
Path scaleNormalizedPathX(Path path, double scale) {
  if (scale == 1.0) return path;
  final bounds = path.getBounds();
  final cx = bounds.center.dx;
  return path.transform(
    (Matrix4.identity()
          // ignore: deprecated_member_use
          ..translate(cx, 0.0, 0.0)
          // ignore: deprecated_member_use
          ..scale(scale, 1.0, 1.0)
          // ignore: deprecated_member_use
          ..translate(-cx, 0.0, 0.0))
        .storage,
  );
}

/// Render scale for the core region from its settled scale and bloat state.
///
/// While bloating, the scale overshoots from `settled * (1 + overshoot)` down
/// to exactly `settled` as the animation value `bloatT` goes 0 → 1; when not
/// bloating, the region renders at its settled scale.
double coreRenderScale({
  required double settledScale,
  required bool bloating,
  required double bloatT,
}) {
  if (!bloating) return settledScale;
  return settledScale * (1.0 + kBloatOvershoot * (1.0 - bloatT));
}

/// Whether a tamagotchi change should (re)start the bloat animation.
///
/// Restarts when a bloat begins, and on every further fullness increase while
/// bloating, so successive meal logs retrigger the overshoot in real-time
/// instead of being swallowed by an already-running animation.
bool shouldRestartBloat({
  required bool bloating,
  required double fullness,
  required double lastFullness,
  required bool wasBloating,
}) {
  if (!bloating) return false;
  if (!wasBloating) return true;
  return fullness > lastFullness;
}

/// Forced split-limb rendering. Normalized draw offsets applied per split
/// segment so joint neighbours are pushed apart on screen (upper arms rise
/// while forearms drop; thighs rise while calves drop). Kept small (~1–2 px at
/// typical sizes) so `muscleAt` hit-testing on the un-offset vector paths keeps
/// resolving to the same segments.
const Map<String, Offset> splitLimbDrawOffsets = {
  'upper_arms': Offset(0.0, -0.012),
  'forearms': Offset(0.0, 0.012),
  'thighs': Offset(0.0, -0.010),
  'calves': Offset(0.0, 0.010),
};

/// Normalized joint line between the upper-arm and forearm vector paths.
const double splitArmJointY = 0.355;

/// Normalized joint line between the thigh and calf vector paths.
const double splitLegJointY = 0.80;

/// Content equality for region-id sets, so the painter repaints when the
/// active set's contents change even if the same instance is reused.
bool sameRegionIdSet(Set<String> a, Set<String> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  return a.containsAll(b);
}

/// Resolves the selection highlight base color for a region: an explicit entry
/// in [overrides] wins; otherwise [fallback] is used.
///
/// The painter builds the selected region's glow, fill and stroke from this
/// base color, so exercise overrides (red primary, orange secondary) always
/// beat the tier heatmap for the selected or logged exercise.
Color selectionBaseColor({
  required Map<String, Color> overrides,
  required String regionId,
  required Color fallback,
}) =>
    overrides[regionId] ?? fallback;
