import 'package:flutter/material.dart';

import '../../../core/domain/body_projection/body_diagram_view_model.dart';
import 'body_segment_geometry.dart';
import 'body_segment_palette.dart';
import 'callout_placement.dart';

/// Draws the schematic figure, its status fills and the blueprint leader lines.
///
/// The painter is a pure function of [viewModel]: it performs no layout side
/// effects and never mutates state, so `shouldRepaint` can safely compare the
/// immutable view model.
class BodyBlueprintPainter extends CustomPainter {
  /// Creates a painter for [viewModel].
  const BodyBlueprintPainter({required this.viewModel});

  /// The immutable snapshot to draw.
  final BodyDiagramViewModel viewModel;

  static const double _strokeWidth = 1.4;
  static const double _leaderWidth = 1.0;
  static const double _dotRadius = 3.0;

  @override
  void paint(Canvas canvas, Size size) {
    _paintAtmosphere(canvas, size);
    _paintLeaderLines(canvas, size);
    _paintFigure(canvas, size);
  }

  void _paintAtmosphere(Canvas canvas, Size size) {
    final glowRect = BodySegmentGeometry.figureRect(size).inflate(34);
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF0EA5E9).withValues(alpha: 0.12),
          const Color(0xFF0EA5E9).withValues(alpha: 0.035),
          Colors.transparent,
        ],
        stops: const [0, 0.58, 1],
      ).createShader(glowRect);
    canvas.drawOval(glowRect, glow);
  }

  void _paintLeaderLines(Canvas canvas, Size size) {
    final leaderPathPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _leaderWidth
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF38BDF8).withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    final leaderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _leaderWidth
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF7DD3FC).withValues(alpha: 0.76);
    final dotGlowPaint = Paint()
      ..color = const Color(0xFF38BDF8).withValues(alpha: 0.34)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    final dotPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFBAE6FD);

    for (final placement in layoutBodyCallouts(size)) {
      final path = buildLeaderPath(placement);
      canvas.drawPath(path, leaderPathPaint);
      canvas.drawPath(path, leaderPaint);
      canvas.drawCircle(placement.anchor, _dotRadius + 3, dotGlowPaint);
      canvas.drawCircle(placement.anchor, _dotRadius, dotPaint);
    }
  }

  void _paintFigure(Canvas canvas, Size size) {
    final paths = BodySegmentGeometry.buildPaths(
      size,
      scaleFor: viewModel.scaleFor,
    );

    for (final segment in BodySegmentGeometry.drawOrder) {
      final path = paths[segment]!;
      final status = viewModel.statusFor(segment);
      final accent = BodySegmentPalette.strokeFor(status);
      final bounds = path.getBounds();

      // A soft offset silhouette gives each articulated piece separation from
      // its neighbours without flattening the transparent blueprint palette.
      canvas.drawPath(
        path.shift(const Offset(1.4, 2.2)),
        Paint()
          ..color = const Color(0xB3000712)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );

      // Concentrated cyan light rolls across each segment, while the darker
      // edge vignette preserves the original status colour as the focal hue.
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.fill
          ..shader = RadialGradient(
            center: const Alignment(-0.34, -0.48),
            radius: 1.18,
            colors: [
              accent.withValues(alpha: 0.42),
              accent.withValues(alpha: 0.17),
              const Color(0xFF061321).withValues(alpha: 0.94),
            ],
            stops: const [0, 0.42, 1],
          ).createShader(bounds),
      );

      canvas.save();
      canvas.clipPath(path);
      canvas.drawRect(
        bounds,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0x2738BDF8),
              Color(0x087DD3FC),
              Color(0x33020A18),
            ],
            stops: [0, 0.46, 1],
          ).createShader(bounds),
      );
      canvas.restore();

      // Diffuse inner glow under the crisp status outline creates a layered
      // neon edge while keeping green/amber/red state colours legible.
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..strokeJoin = StrokeJoin.round
          ..color = accent.withValues(alpha: 0.44)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = _strokeWidth
          ..strokeJoin = StrokeJoin.round
          ..color = accent,
      );

      // Partial cool trace catches the upper-left contour like a technical
      // drafting highlight; the complete colored outline remains underneath.
      for (final metric in path.computeMetrics()) {
        final trace = metric.extractPath(0, metric.length * 0.28);
        canvas.drawPath(
          trace,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.72
            ..strokeCap = StrokeCap.round
            ..color = const Color(0xFFBAE6FD).withValues(alpha: 0.78),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant BodyBlueprintPainter oldDelegate) =>
      oldDelegate.viewModel != viewModel;
}
