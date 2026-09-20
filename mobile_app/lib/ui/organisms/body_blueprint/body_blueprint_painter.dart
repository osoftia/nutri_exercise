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
  static const double _leaderOpacity = 0.6;
  static const double _dotRadius = 3.0;
  static const Color _leaderColor = Color(0xFF94A3B8);

  @override
  void paint(Canvas canvas, Size size) {
    _paintLeaderLines(canvas, size);
    _paintFigure(canvas, size);
  }

  void _paintLeaderLines(Canvas canvas, Size size) {
    final leaderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _leaderWidth
      ..color = _leaderColor.withValues(alpha: _leaderOpacity);
    final dotPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = _leaderColor.withValues(alpha: _leaderOpacity);

    for (final placement in layoutBodyCallouts(size)) {
      canvas.drawPath(buildLeaderPath(placement), leaderPaint);
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
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.fill
          ..color = BodySegmentPalette.fillFor(status),
      );
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = _strokeWidth
          ..strokeJoin = StrokeJoin.round
          ..color = BodySegmentPalette.strokeFor(status),
      );
    }
  }

  @override
  bool shouldRepaint(covariant BodyBlueprintPainter oldDelegate) =>
      oldDelegate.viewModel != viewModel;
}
