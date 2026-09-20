import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Paints a subtle technical-drafting grid behind the unified body blueprint.
///
/// Fine coordinate lines (a [cell]-sized lattice) sit behind the figure with
/// brighter major lines every [majorEvery] cells and a faint centre crosshair,
/// matching the engineering-poster aesthetic without competing with the body.
class BlueprintGridPainter extends CustomPainter {
  /// Creates a grid painter.
  const BlueprintGridPainter({
    this.cell = 28,
    this.majorEvery = 4,
    this.lineColor = AppColors.primary500,
    this.minorOpacity = 0.06,
    this.majorOpacity = 0.13,
    this.axisOpacity = 0.2,
  });

  /// Spacing of the fine lattice, in logical pixels.
  final double cell;

  /// Every [majorEvery]-th line is drawn as a brighter major line.
  final int majorEvery;

  /// Base colour of every grid line.
  final Color lineColor;

  /// Opacity of a fine line.
  final double minorOpacity;

  /// Opacity of a major line.
  final double majorOpacity;

  /// Opacity of the centre crosshair.
  final double axisOpacity;

  @override
  void paint(Canvas canvas, Size size) {
    if (cell <= 0 || size.isEmpty) return;

    final minor = Paint()
      ..strokeWidth = 1
      ..isAntiAlias = false
      ..color = lineColor.withValues(alpha: minorOpacity);
    final major = Paint()
      ..strokeWidth = 1
      ..isAntiAlias = false
      ..color = lineColor.withValues(alpha: majorOpacity);
    final axis = Paint()
      ..strokeWidth = 1.2
      ..isAntiAlias = false
      ..color = lineColor.withValues(alpha: axisOpacity);

    var index = 0;
    for (double x = 0; x <= size.width; x += cell, index++) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        index % majorEvery == 0 ? major : minor,
      );
    }
    index = 0;
    for (double y = 0; y <= size.height; y += cell, index++) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        index % majorEvery == 0 ? major : minor,
      );
    }

    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      axis,
    );
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      axis,
    );
  }

  @override
  bool shouldRepaint(covariant BlueprintGridPainter oldDelegate) =>
      oldDelegate.cell != cell ||
      oldDelegate.majorEvery != majorEvery ||
      oldDelegate.lineColor != lineColor ||
      oldDelegate.minorOpacity != minorOpacity ||
      oldDelegate.majorOpacity != majorOpacity ||
      oldDelegate.axisOpacity != axisOpacity;
}
