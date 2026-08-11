import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/constants/muscle_vectors.dart';
import '../../core/theme/app_theme.dart';

const double _kPadFactor = 0.03;
const double _kAspectRatio = 1.6;
const Duration _kGlowDuration = Duration(milliseconds: 300);

class InteractiveBodyMap extends StatefulWidget {
  const InteractiveBodyMap({
    super.key,
    this.selectedMuscle,
    this.onMuscleSelected,
  });

  final String? selectedMuscle;
  final ValueChanged<String?>? onMuscleSelected;

  @override
  State<InteractiveBodyMap> createState() => _InteractiveBodyMapState();
}

class _InteractiveBodyMapState extends State<InteractiveBodyMap>
    with SingleTickerProviderStateMixin {
  late String? _selected;
  late final AnimationController _glowController;
  double _glow = 0;

  @override
  void initState() {
    super.initState();
    _selected = widget.selectedMuscle;
    _glowController = AnimationController(vsync: this, duration: _kGlowDuration)
      ..repeat();
    _glowController.addListener(() {
      setState(() => _glow = _glowController.value);
    });
  }

  @override
  void didUpdateWidget(InteractiveBodyMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedMuscle != oldWidget.selectedMuscle) {
      _selected = widget.selectedMuscle;
    }
  }

  @override
  void dispose() {
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
              painter: _BodyMapPainter(selectedMuscle: _selected, glow: _glow),
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

Path _screenPath(MuscleRegion region, Size size) {
  final box = _figureBox(region.view, size);
  final scaled = region.normalizedPath.transform(
    (Matrix4.identity()..scale(box.width, box.height, 1.0))
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
  const _BodyMapPainter({required this.selectedMuscle, required this.glow});

  final String? selectedMuscle;
  final double glow;

  @override
  void paint(Canvas canvas, Size size) {
    _paintSilhouette(canvas, size, MuscleView.front);
    _paintSilhouette(canvas, size, MuscleView.back);

    final hasSelection = selectedMuscle != null;
    for (final region in muscleRegions) {
      final isSelected = region.id == selectedMuscle;
      final path = _screenPath(region, size);
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.fill
          ..color = AppColors.neutralMuscle.withValues(
            alpha: isSelected ? 0.0 : (hasSelection ? 0.12 : 0.22),
          ),
      );
      if (!isSelected) {
        canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4
            ..color = AppColors.neutralMuscle.withValues(alpha: 0.55),
        );
      }
    }

    if (hasSelection) {
      for (final region in muscleRegions) {
        if (region.id != selectedMuscle) continue;
        final path = _screenPath(region, size);
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

  void _paintSilhouette(Canvas canvas, Size size, MuscleView view) {
    final box = _figureBox(view, size);
    final source = view == MuscleView.front ? frontSilhouette : backSilhouette;
    final path = source.transform(
      (Matrix4.identity()..scale(box.width, box.height, 1.0))
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
        oldDelegate.glow != glow;
  }
}
