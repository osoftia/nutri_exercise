import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../atoms/typography.dart';
import 'neumorphic_container.dart';

/// Public painter so tests can assert the sweep angle for a given progress.
class CircularProgressPainter extends CustomPainter {
  const CircularProgressPainter({
    required this.progress,
    this.color = AppColors.primary400,
  });

  final double progress;
  final Color color;

  /// Angle (radians) the progress arc sweeps, starting at 12 o'clock.
  double get sweepAngle => 2 * math.pi * progress;

  double get startAngle => -math.pi / 2;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide / 2) - 6;
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..color = AppColors.surface900;
    canvas.drawCircle(center, radius, track);

    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(CircularProgressPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

/// A neumorphic circular progress ring for a single metric.
class NeumorphicCircularProgress extends StatelessWidget {
  const NeumorphicCircularProgress({
    super.key,
    required this.title,
    required this.progress,
    required this.valueLabel,
    this.color = AppColors.primary400,
  });

  final String title;

  /// Progress in `[0, 1]`.
  final double progress;
  final String valueLabel;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return NeumorphicContainer(
      child: Column(
        children: [
          SizedBox(
            width: 96,
            height: 96,
            child: CustomPaint(
              painter: CircularProgressPainter(
                progress: progress.clamp(0.0, 1.0),
                color: color,
              ),
              child: Center(child: AppText(valueLabel)),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppCaption(title),
        ],
      ),
    );
  }
}
