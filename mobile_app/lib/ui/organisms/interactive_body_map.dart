import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/constants/muscle_vectors.dart';
import '../../core/constants/tamagotchi_groups.dart';
import '../../core/state/muscle_tamagotchi_state.dart';
import '../../core/theme/app_theme.dart';

const double _kPadFactor = 0.03;
const double _kAspectRatio = 1.6;
const double _kMassScale = 0.5;
const Duration _kGlowDuration = Duration(milliseconds: 300);

/// Size factor applied to a muscle region for a given mass.
///
/// A mass equal to the baseline renders at `1.0` (no change); a full `1.0`
/// bulges larger and a `0.0` shrinks.
double scaleForMass(double mass) =>
    1.0 + _kMassScale * (mass - MuscleTamagotchiState.baseline);

Path _scaleNormalizedPath(Path path, double scale) {
  if (scale == 1.0) return path;
  final bounds = path.getBounds();
  final cx = bounds.center.dx;
  final cy = bounds.center.dy;
  return path.transform(
    (Matrix4.identity()
          ..translateByDouble(cx, cy, 0.0, 1.0)
          ..scaleByDouble(scale, scale, 1.0, 1.0)
          ..translateByDouble(-cx, -cy, 0.0, 1.0))
        .storage,
  );
}

class InteractiveBodyMap extends StatefulWidget {
  const InteractiveBodyMap({
    super.key,
    this.selectedMuscle,
    this.onMuscleSelected,
    this.activeRegions = const {},
    this.tamagotchiState,
  });

  final String? selectedMuscle;
  final ValueChanged<String?>? onMuscleSelected;
  final Set<String> activeRegions;
  final MuscleTamagotchiState? tamagotchiState;

  @override
  State<InteractiveBodyMap> createState() => _InteractiveBodyMapState();
}

class _InteractiveBodyMapState extends State<InteractiveBodyMap>
    with SingleTickerProviderStateMixin {
  late String? _selected;
  late final AnimationController _glowController;
  double _glow = 0;
  MuscleTamagotchiState? _tamagotchiState;
  int _revision = 0;

  @override
  void initState() {
    super.initState();
    _selected = widget.selectedMuscle;
    _glowController = AnimationController(vsync: this, duration: _kGlowDuration)
      ..repeat();
    _glowController.addListener(() {
      setState(() => _glow = _glowController.value);
    });
    _listenToTamagotchi();
  }

  void _listenToTamagotchi() {
    _tamagotchiState?.removeListener(_onTamagotchiChanged);
    _tamagotchiState = widget.tamagotchiState;
    _tamagotchiState?.addListener(_onTamagotchiChanged);
  }

  void _onTamagotchiChanged() => setState(() => _revision++);

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
    _tamagotchiState?.removeListener(_onTamagotchiChanged);
    _glowController.dispose();
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
      aspectRatio: _kAspectRatio,
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
              ),
            ),
          );
        },
      ),
    );
  }
}

Rect _figureBox(MuscleView view, Size size) {
  final pad = size.width * _kPadFactor;
  final side = math.min((size.width - pad * 3) / 2, size.height - pad * 2);
  final top = (size.height - side) / 2;
  final left = (size.width - side * 2 - pad) / 2;
  return view == MuscleView.front
      ? Rect.fromLTWH(left, top, side, side)
      : Rect.fromLTWH(left + side + pad, top, side, side);
}

Path _screenPath(MuscleRegion region, Size size, {double scale = 1.0}) {
  final box = _figureBox(region.view, size);
  final normalized = _scaleNormalizedPath(region.normalizedPath, scale);
  final scaled = normalized.transform(
    (Matrix4.identity()
        ..scaleByDouble(box.width, box.height, 1.0, 1.0))
        .storage,
  );
  return scaled.shift(box.topLeft);
}

MuscleRegion? muscleAt(Offset position, Size size) {
  for (final region in muscleRegions) {
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
  });

  final String? selectedMuscle;
  final double glow;
  final Set<String> activeRegions;
  final MuscleTamagotchiState? tamagotchiState;
  final int revision;

  @override
  void paint(Canvas canvas, Size size) {
    _paintSilhouette(canvas, size, MuscleView.front);
    _paintSilhouette(canvas, size, MuscleView.back);

    final hasSelection = selectedMuscle != null;
    for (final region in muscleRegions) {
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

    if (hasSelection) {
      for (final region in muscleRegions) {
        if (region.id != selectedMuscle) continue;
        final path = _regionPath(region, size);
        canvas.drawPath(
          path,
          Paint()
            ..color = AppColors.primary500.withValues(alpha: 0.25 + 0.30 * glow)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
        );
        canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.fill
            ..color = AppColors.primary500.withValues(alpha: 0.60),
        );
        canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.0
            ..color = AppColors.primary300,
        );
      }
    }

    _paintViewLabels(canvas, size);
  }

  Path _regionPath(MuscleRegion region, Size size) {
    if (tamagotchiState == null) return _screenPath(region, size);
    final group = tamagotchiGroupForRegion(region.id);
    final mass = group == null
        ? MuscleTamagotchiState.baseline
        : tamagotchiState!.massOf(group);
    return _screenPath(region, size, scale: scaleForMass(mass));
  }

  Color _regionColor(MuscleRegion region) {
    if (tamagotchiState == null) return AppColors.neutralMuscle;
    final group = tamagotchiGroupForRegion(region.id);
    if (group == null) return AppColors.neutralMuscle;
    return tierColor(tamagotchiState!.tierOf(group));
  }

  void _paintSilhouette(Canvas canvas, Size size, MuscleView view) {
    final box = _figureBox(view, size);
    final source = view == MuscleView.front ? frontSilhouette : backSilhouette;
    final path = source.transform(
      (Matrix4.identity()
          ..scaleByDouble(box.width, box.height, 1.0, 1.0))
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
        oldDelegate.activeRegions != activeRegions ||
        oldDelegate.revision != revision;
  }
}
