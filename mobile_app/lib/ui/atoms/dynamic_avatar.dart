import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Paints a stylized human silhouette whose width morphs with [morph]
/// (`0 = thinnest`, `0.5 = normal`, `1 = widest`).
class DynamicAvatarPainter extends CustomPainter {
  const DynamicAvatarPainter({required this.morph});

  /// Normalized morph factor in `[0, 1]`.
  final double morph;

  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.shortestSide;
    final cx = size.width / 2;
    final t = morph.clamp(0.0, 1.0);
    double lerp(double a, double b, double k) => a + (b - a) * k;

    final fill = Paint()
      ..style = PaintingStyle.fill
      ..color = AppColors.primary500.withOpacity(0.35);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = AppColors.primary400;

    // Head.
    final headRadius = lerp(0.045, 0.058, t) * unit;
    final headCenter = Offset(cx, 0.10 * unit);
    canvas.drawCircle(headCenter, headRadius, fill);
    canvas.drawCircle(headCenter, headRadius, stroke);

    // Torso (shoulders -> waist -> hips), widths interpolate with morph.
    final shoulderY = 0.19 * unit;
    final waistY = 0.42 * unit;
    final hipY = 0.52 * unit;
    final shoulderHalf = lerp(0.16, 0.21, t) * unit;
    final waistHalf = lerp(0.11, 0.20, t) * unit;
    final hipHalf = lerp(0.14, 0.20, t) * unit;

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
    final armHalf = lerp(0.05, 0.075, t) * unit;
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
    final legHalf = lerp(0.06, 0.09, t) * unit;
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
    final rect = Rect.fromLTRB(top.dx - half, top.dy, bottom.dx + half, bottom.dy);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(half));
    canvas.drawRRect(rrect, fill);
    canvas.drawRRect(rrect, stroke);
  }

  @override
  bool shouldRepaint(DynamicAvatarPainter oldDelegate) =>
      oldDelegate.morph != morph;
}

/// A neumorphic dynamic avatar whose silhouette widens as [morph] grows.
class DynamicAvatar extends StatelessWidget {
  const DynamicAvatar({super.key, required this.morph});

  final double morph;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      width: double.infinity,
      child: CustomPaint(
        key: const Key('dynamic_avatar'),
        painter: DynamicAvatarPainter(morph: morph),
      ),
    );
  }
}
