import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Paints a human silhouette whose shoulders and waist morph independently.
///
/// `shoulderFactor` (`0` narrow … `1` broad) and `waistFactor` (`0` slim …
/// `1` wide) are the two projection dimensions derived from the SQLite plan.
class ProjectionAvatarPainter extends CustomPainter {
  const ProjectionAvatarPainter({
    required this.shoulderFactor,
    required this.waistFactor,
  });

  final double shoulderFactor;
  final double waistFactor;

  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.shortestSide;
    final cx = size.width / 2;
    final shoulder = shoulderFactor.clamp(0.0, 1.0);
    final waist = waistFactor.clamp(0.0, 1.0);
    double lerp(double a, double b, double k) => a + (b - a) * k;

    final fill = Paint()
      ..style = PaintingStyle.fill
      ..color = AppColors.primary500.withOpacity(0.35);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = AppColors.primary400;

    // Head (slight size response to overall build).
    final headRadius = lerp(0.045, 0.058, (shoulder + waist) / 2) * unit;
    final headCenter = Offset(cx, 0.10 * unit);
    canvas.drawCircle(headCenter, headRadius, fill);
    canvas.drawCircle(headCenter, headRadius, stroke);

    // Torso — shoulders driven by shoulderFactor, waist by waistFactor.
    final shoulderY = 0.19 * unit;
    final waistY = 0.42 * unit;
    final hipY = 0.52 * unit;
    final shoulderHalf = lerp(0.14, 0.26, shoulder) * unit;
    final waistHalf = lerp(0.08, 0.24, waist) * unit;
    final hipHalf = lerp(0.12, 0.22, (shoulder + waist) / 2) * unit;

    final torso = Path()
      ..moveTo(cx - shoulderHalf, shoulderY)
      ..cubicTo(
        cx - shoulderHalf,
        (shoulderY + waistY) / 2,
        cx - waistHalf,
        (shoulderY + waistY) / 2,
        cx - waistHalf,
        waistY,
      )
      ..cubicTo(
        cx - waistHalf,
        (waistY + hipY) / 2,
        cx - hipHalf,
        (waistY + hipY) / 2,
        cx - hipHalf,
        hipY,
      )
      ..lineTo(cx + hipHalf, hipY)
      ..cubicTo(
        cx + hipHalf,
        (waistY + hipY) / 2,
        cx + waistHalf,
        (waistY + hipY) / 2,
        cx + waistHalf,
        waistY,
      )
      ..cubicTo(
        cx + waistHalf,
        (shoulderY + waistY) / 2,
        cx + shoulderHalf,
        (shoulderY + waistY) / 2,
        cx + shoulderHalf,
        shoulderY,
      )
      ..close();
    canvas.drawPath(torso, fill);
    canvas.drawPath(torso, stroke);

    // Arms.
    final armTop = shoulderY + 0.01 * unit;
    final armBottom = 0.50 * unit;
    final armHalf = lerp(0.05, 0.075, shoulder) * unit;
    final armGap = shoulderHalf + armHalf;
    _drawLimb(
      canvas,
      Offset(cx - armGap, armTop),
      Offset(cx - armGap, armBottom),
      armHalf,
      fill,
      stroke,
    );
    _drawLimb(
      canvas,
      Offset(cx + armGap, armTop),
      Offset(cx + armGap, armBottom),
      armHalf,
      fill,
      stroke,
    );

    // Legs.
    final legBottom = 0.93 * unit;
    final legHalf = lerp(0.06, 0.09, (shoulder + waist) / 2) * unit;
    final legGap = hipHalf * 0.5;
    _drawLimb(
      canvas,
      Offset(cx - legGap, hipY),
      Offset(cx - legGap, legBottom),
      legHalf,
      fill,
      stroke,
    );
    _drawLimb(
      canvas,
      Offset(cx + legGap, hipY),
      Offset(cx + legGap, legBottom),
      legHalf,
      fill,
      stroke,
    );
  }

  void _drawLimb(
    Canvas canvas,
    Offset top,
    Offset bottom,
    double half,
    Paint fill,
    Paint stroke,
  ) {
    final rect = Rect.fromLTRB(
      top.dx - half,
      top.dy,
      bottom.dx + half,
      bottom.dy,
    );
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(half));
    canvas.drawRRect(rrect, fill);
    canvas.drawRRect(rrect, stroke);
  }

  @override
  bool shouldRepaint(ProjectionAvatarPainter oldDelegate) =>
      oldDelegate.shoulderFactor != shoulderFactor ||
      oldDelegate.waistFactor != waistFactor;
}

/// A neumorphic avatar that smoothly animates its shoulder/waist morph when
/// the selected milestone changes.
class ProjectionAvatar extends StatelessWidget {
  const ProjectionAvatar({
    super.key,
    required this.shoulderFactor,
    required this.waistFactor,
  });

  final double shoulderFactor;
  final double waistFactor;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: shoulderFactor),
      duration: const Duration(milliseconds: 500),
      builder: (context, shoulder, _) {
        return TweenAnimationBuilder<double>(
          tween: Tween<double>(end: waistFactor),
          duration: const Duration(milliseconds: 500),
          builder: (context, waist, _) {
            return SizedBox(
              height: 240,
              width: double.infinity,
              child: CustomPaint(
                key: const Key('projection_avatar'),
                painter: ProjectionAvatarPainter(
                  shoulderFactor: shoulder,
                  waistFactor: waist,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
