import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/constants/muscle_vectors.dart';
import '../../core/constants/tamagotchi_groups.dart';
import '../../core/state/muscle_tamagotchi_state.dart';
import '../../core/theme/app_theme.dart';
import 'body_map_geometry.dart';

/// Re-exported geometry/decision helpers so existing importers and tests keep
/// resolving `scaleForMass`, `coreRenderScale`, `selectionBaseColor`, etc.
export 'body_map_geometry.dart';

class InteractiveBodyMap extends StatefulWidget {
  const InteractiveBodyMap({
    super.key,
    this.selectedMuscle,
    this.onMuscleSelected,
    this.activeRegions = const {},
    this.tamagotchiState,
    this.bodyWidthFactor = 1.0,
    this.animate = true,
  });

  final String? selectedMuscle;
  final ValueChanged<String?>? onMuscleSelected;
  final Set<String> activeRegions;
  final MuscleTamagotchiState? tamagotchiState;

  /// Baseline body width factor (from the user's BMI); `1.0` is neutral.
  final double bodyWidthFactor;

  /// Whether the selection glow animates. Disable for static captures (e.g.
  /// the hidden social share card) to avoid perpetual ticking.
  final bool animate;

  @override
  State<InteractiveBodyMap> createState() => _InteractiveBodyMapState();
}

class _InteractiveBodyMapState extends State<InteractiveBodyMap>
    with TickerProviderStateMixin {
  late String? _selected;
  late final AnimationController _glowController;
  late final AnimationController _bloatController;
  double _glow = 0;
  double _bloat = 0;
  bool _coreBloating = false;
  double _lastFullness = 0.0;
  MuscleTamagotchiState? _tamagotchiState;
  int _revision = 0;
  int _lastSeenMealCount = 0;
  bool _foodFlash = false;
  Timer? _flashTimer;

  @override
  void initState() {
    super.initState();
    _selected = widget.selectedMuscle;
    _glowController = AnimationController(vsync: this, duration: kGlowDuration);
    if (widget.animate) {
      _glowController.repeat();
    }
    _glowController.addListener(() {
      setState(() => _glow = _glowController.value);
    });
    _bloatController = AnimationController(vsync: this, duration: kBloatDuration)
      ..addListener(() {
        setState(() => _bloat = _bloatController.value);
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _tamagotchiState?.settleCore();
        }
      });
    _listenToTamagotchi();
  }

  void _listenToTamagotchi() {
    _tamagotchiState?.removeListener(_onTamagotchiChanged);
    _tamagotchiState = widget.tamagotchiState;
    _tamagotchiState?.addListener(_onTamagotchiChanged);
    _lastSeenMealCount = _tamagotchiState?.mealCount ?? 0;
    _syncBloat();
  }

  void _onTamagotchiChanged() {
    setState(() => _revision++);
    _syncBloat();
    _syncFoodFlash();
  }

  /// M35 Task 1: stomach red-flash debug. Every food log bumps
  /// [MuscleTamagotchiState.mealCount]; on a bump the stomach flashes
  /// bright red for [MuscleTamagotchiState.foodFlashDuration], proving the
  /// bloat state → UI re-render path is live.
  void _syncFoodFlash() {
    final meals = _tamagotchiState?.mealCount ?? 0;
    if (meals <= _lastSeenMealCount) return;
    _lastSeenMealCount = meals;
    _flashTimer?.cancel();
    setState(() => _foodFlash = true);
    _flashTimer = Timer(MuscleTamagotchiState.foodFlashDuration, () {
      if (!mounted) return;
      setState(() => _foodFlash = false);
    });
  }

  void _syncBloat() {
    final state = _tamagotchiState;
    final bloat = state?.coreIsBloating ?? false;
    final fullness = state?.coreFullness ?? 0.0;
    if (shouldRestartBloat(
      bloating: bloat,
      fullness: fullness,
      lastFullness: _lastFullness,
      wasBloating: _coreBloating,
    )) {
      _bloatController.forward(from: 0.0);
    }
    _coreBloating = bloat;
    _lastFullness = fullness;
    if (!bloat) {
      _bloat = 0;
    }
  }

  @override
  void didUpdateWidget(InteractiveBodyMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedMuscle != oldWidget.selectedMuscle) {
      _selected = widget.selectedMuscle;
    }
    if (widget.tamagotchiState != oldWidget.tamagotchiState) {
      _listenToTamagotchi();
    }
  }

  @override
  void dispose() {
    _flashTimer?.cancel();
    _tamagotchiState?.removeListener(_onTamagotchiChanged);
    _glowController.dispose();
    _bloatController.dispose();
    super.dispose();
  }

  void _handleTap(TapUpDetails details) {
    final size = context.size;
    if (size == null) return;
    final hit = muscleAt(details.localPosition, size);
    if (hit == null) return;
    final next = hit.id == _selected ? null : hit.id;
    setState(() => _selected = next);
    widget.onMuscleSelected?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: kAspectRatio,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: _handleTap,
            child: CustomPaint(
              size: Size(constraints.maxWidth, constraints.maxHeight),
              painter: _BodyMapPainter(
                selectedMuscle: _selected,
                glow: _glow,
                activeRegions: widget.activeRegions,
                tamagotchiState: _tamagotchiState,
                revision: _revision,
                bodyWidthFactor: widget.bodyWidthFactor,
                coreBloating: _coreBloating,
                bloat: _bloat,
                foodFlash: _foodFlash,
              ),
            ),
          );
        },
      ),
    );
  }
}

Rect _figureBox(MuscleView view, Size size) {
  final pad = size.width * kPadFactor;
  final side = math.min((size.width - pad * 3) / 2, size.height - pad * 2);
  final top = (size.height - side) / 2;
  final left = (size.width - side * 2 - pad) / 2;
  return view == MuscleView.front
      ? Rect.fromLTWH(left, top, side, side)
      : Rect.fromLTWH(left + side + pad, top, side, side);
}

Path _screenPath(
  MuscleRegion region,
  Size size, {
  double scale = 1.0,
  double widthFactor = 1.0,
}) {
  final box = _figureBox(region.view, size);
  final normalized = scaleNormalizedPath(region.normalizedPath, scale);
  final widthAdjusted = scaleNormalizedPathX(normalized, widthFactor);
  final scaled = widthAdjusted.transform(
      (Matrix4.identity()
          // ignore: deprecated_member_use
          ..scale(box.width, box.height, 1.0))
          .storage,
  );
  return scaled.shift(box.topLeft);
}

MuscleRegion? muscleAt(Offset position, Size size) {
  // Hit-test in reverse paint order so taps resolve to the topmost-painted
  // region. The split anatomies (upper arms vs forearms, thighs vs calves)
  // are separated by visible gaps (M35), so seam taps fall between segments
  // while taps inside a segment resolve to it.
  for (var i = muscleRegions.length - 1; i >= 0; i--) {
    final region = muscleRegions[i];
    if (_screenPath(region, size).contains(position)) return region;
  }
  return null;
}

class _BodyMapPainter extends CustomPainter {
  const _BodyMapPainter({
    required this.selectedMuscle,
    required this.glow,
    required this.activeRegions,
    required this.tamagotchiState,
    required this.revision,
    required this.bodyWidthFactor,
    required this.coreBloating,
    required this.bloat,
    required this.foodFlash,
  });

  final String? selectedMuscle;
  final double glow;
  final Set<String> activeRegions;
  final MuscleTamagotchiState? tamagotchiState;
  final int revision;
  final double bodyWidthFactor;
  final bool coreBloating;
  final double bloat;

  /// M35 Task 1: while true the stomach (`abs`) renders bright red.
  final bool foodFlash;

  @override
  void paint(Canvas canvas, Size size) {
    _paintSilhouette(canvas, size, MuscleView.front);
    _paintSilhouette(canvas, size, MuscleView.back);

    final hasSelection = selectedMuscle != null;
    // M36 Task 2 (pass 1/5): torso + every other NON-split region. Split
    // limbs are skipped here — each gets its own explicit pass below so no
    // two limb segments ever share a drawing command.
    for (final region in muscleRegions) {
      if (isSplitLimbRegion(region.id)) continue;
      final isSelected = region.id == selectedMuscle;
      final path = _regionPath(region, size);
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.fill
          ..color = _regionColor(region).withValues(
            alpha: isSelected ? 0.0 : (hasSelection ? 0.12 : 0.35),
          ),
      );
      if (!isSelected) {
        final isActive = activeRegions.contains(region.id);
        canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = isActive ? 2.0 : 1.4
            ..color = isActive
                ? AppColors.accent
                : AppColors.neutralMuscle.withValues(alpha: 0.55),
        );
      }
    }

    // M36 Task 2 (passes 2–5/5): forced split rendering. One dedicated
    // command stream per limb segment, each shifted by its own
    // [splitLimbDrawOffsets] entry so Upper Arms / Forearms / Thighs /
    // Calves are 100% visibly independent on screen.
    _paintSplitSegment(canvas, size, 'upper_arms', hasSelection);
    _paintSplitSegment(canvas, size, 'forearms', hasSelection);
    _paintSplitSegment(canvas, size, 'thighs', hasSelection);
    _paintSplitSegment(canvas, size, 'calves', hasSelection);
    // Joint separators are cut last so growth scaling can never re-close
    // the split.
    _paintSplitSeparators(canvas, size);

    if (hasSelection) {
      for (final region in muscleRegions) {
        if (region.id != selectedMuscle) continue;
        final path = _regionPath(region, size);
        final highlight = _selectionBaseColor(region);
        canvas.drawPath(
          path,
          Paint()
            ..color =
                highlight.withValues(alpha: 0.25 + 0.30 * glow)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
        );
        canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.fill
            ..color = highlight.withValues(alpha: 0.60),
        );
        canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.0
            ..color = highlight,
        );
      }
    }

    _paintViewLabels(canvas, size);
  }

  Path _regionPath(MuscleRegion region, Size size) {
    if (tamagotchiState == null) {
      return _screenPath(region, size, widthFactor: bodyWidthFactor);
    }
    final group = tamagotchiGroupForRegion(region.id);
    final mass = group == null
        ? MuscleTamagotchiState.baseline
        : tamagotchiState!.massOf(group);
    final scale = _regionScale(region, mass);
    return _screenPath(
      region,
      size,
      scale: scale,
      widthFactor: bodyWidthFactor,
    );
  }

  /// The render scale for [region]: the core region bloats (overshoots its
  /// settled scale while [coreBloating]) then settles at its permanent,
  /// fullness-proportional size; every other region uses a plain mass scale.
  double _regionScale(MuscleRegion region, double mass) {
    final base = scaleForMass(mass);
    if (tamagotchiGroupForRegion(region.id) != MuscleTamagotchiGroup.core) {
      return base;
    }
    return coreRenderScale(
      settledScale: tamagotchiState!.settledCoreScale(),
      bloating: coreBloating,
      bloatT: bloat,
    );
  }

  Color _regionColor(MuscleRegion region) {
    // M35 Task 1: food-flash debug beats everything on the stomach so a
    // freshly logged meal is unmistakable for 2 seconds.
    if (foodFlash && region.id == 'abs') return kFoodFlashColor;
    if (tamagotchiState == null) return AppColors.neutralMuscle;
    final group = tamagotchiGroupForRegion(region.id);
    if (group == null) return AppColors.neutralMuscle;
    if (group == MuscleTamagotchiGroup.core && coreBloating) {
      return kCoreBloatColor;
    }
    if (tamagotchiState!.regionColorOverrides.containsKey(region.id)) {
      return tamagotchiState!.regionColorOverrides[region.id]!;
    }
    return tierColor(tamagotchiState!.tierOf(group));
  }

  /// Base color for the selected-region highlight: the region's explicit
  /// override when one exists, otherwise the neutral selection blue. This
  /// keeps exercise colors (red primary, orange secondary) on top of tiers.
  Color _selectionBaseColor(MuscleRegion region) => selectionBaseColor(
        overrides: tamagotchiState?.regionColorOverrides ?? const {},
        regionId: region.id,
        fallback: AppColors.primary500,
      );

  /// M36 Task 2: the offset-shifted screen path for a split-limb segment.
  /// The mass scale from [_regionPath] still applies; the segment is then
  /// pushed apart from its joint neighbour by [splitLimbDrawOffsets].
  Path _splitLimbPath(MuscleRegion region, Size size) {
    final path = _regionPath(region, size);
    final offset = splitLimbDrawOffsets[region.id];
    if (offset == null || offset == Offset.zero) return path;
    final box = _figureBox(region.view, size);
    return path.shift(
      Offset(offset.dx * box.width, offset.dy * box.height),
    );
  }

  /// M36 Task 2: one dedicated drawing command stream for a single
  /// split-limb [segmentId] (`upper_arms`, `forearms`, `thighs` or
  /// `calves`). Each segment keeps its own fill + own-color outline
  /// identity (thicker than torso strokes) so adjacent same-tier segments
  /// can never merge into a single-block limb.
  void _paintSplitSegment(
    Canvas canvas,
    Size size,
    String segmentId,
    bool hasSelection,
  ) {
    for (final region in muscleRegions) {
      if (region.id != segmentId) continue;
      final isSelected = region.id == selectedMuscle;
      final path = _splitLimbPath(region, size);
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.fill
          ..color = _regionColor(region).withValues(
            alpha: isSelected ? 0.0 : (hasSelection ? 0.12 : 0.35),
          ),
      );
      if (!isSelected) {
        final isActive = activeRegions.contains(region.id);
        canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = isActive ? 2.4 : 2.0
            ..color = isActive ? AppColors.accent : _regionColor(region),
        );
      }
    }
  }

  /// M36 Task 2: joint separator cuts painted after every segment, in the
  /// page-background color, exactly over the vector gaps
  /// ([splitArmJointY]/[splitLegJointY]). Growth scaling happens around
  /// each path's own centre, so without this final cut a maxed-out mass
  /// could visually re-close the joint — the separator forces the split.
  void _paintSplitSeparators(Canvas canvas, Size size) {
    final cut = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = AppColors.surface900;
    for (final view in MuscleView.values) {
      final box = _figureBox(view, size);
      Offset at(double nx, double ny) =>
          Offset(box.left + nx * box.width, box.top + ny * box.height);
      // Arm joints: narrow strips over each arm's x-range only, so the
      // chest/abs torso paint is never touched.
      canvas.drawLine(at(0.17, splitArmJointY), at(0.31, splitArmJointY), cut);
      canvas.drawLine(at(0.69, splitArmJointY), at(0.83, splitArmJointY), cut);
      // Leg joints.
      canvas.drawLine(at(0.36, splitLegJointY), at(0.51, splitLegJointY), cut);
      canvas.drawLine(at(0.49, splitLegJointY), at(0.64, splitLegJointY), cut);
    }
  }

  void _paintSilhouette(Canvas canvas, Size size, MuscleView view) {
    final box = _figureBox(view, size);
    final source = view == MuscleView.front ? frontSilhouette : backSilhouette;
    final widthAdjusted = scaleNormalizedPathX(source, bodyWidthFactor);
    final path = widthAdjusted.transform(
      (Matrix4.identity()
          // ignore: deprecated_member_use
        ..scale(box.width, box.height, 1.0))
          .storage,
    );
    canvas.drawPath(
      path.shift(box.topLeft),
      Paint()
        ..style = PaintingStyle.fill
        ..color = AppColors.surface800.withValues(alpha: 0.55),
    );
    canvas.drawPath(
      path.shift(box.topLeft),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = AppColors.textLow.withValues(alpha: 0.45),
    );
  }

  void _paintViewLabels(Canvas canvas, Size size) {
    _paintLabel(canvas, 'Front', _figureBox(MuscleView.front, size));
    _paintLabel(canvas, 'Back', _figureBox(MuscleView.back, size));
  }

  void _paintLabel(Canvas canvas, String text, Rect box) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: AppColors.textLow,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      Offset(box.center.dx - painter.width / 2, box.bottom + 6),
    );
  }

  @override
  bool shouldRepaint(_BodyMapPainter oldDelegate) {
    return oldDelegate.selectedMuscle != selectedMuscle ||
        oldDelegate.glow != glow ||
        !sameRegionIdSet(oldDelegate.activeRegions, activeRegions) ||
        oldDelegate.revision != revision ||
        oldDelegate.bodyWidthFactor != bodyWidthFactor ||
        oldDelegate.coreBloating != coreBloating ||
        oldDelegate.bloat != bloat ||
        oldDelegate.foodFlash != foodFlash;
  }
}
