import 'dart:ui';

import '../../../core/domain/body_projection/body_segment.dart';

/// Pure geometry for the technical-blueprint figure.
///
/// All anatomy is expressed in *units of the figure height* with `x` measured
/// from the vertical centre line, so the figure scales to any card width
/// without distortion. The painter and the hit tester both consume this class,
/// which keeps `paint()` free of layout side effects.
abstract final class BodySegmentGeometry {

  /// Figure width divided by figure height.
  static const double figureAspectRatio = 0.62;

  /// Width of the visible elbow / knee joint gap, in units of figure height.
  ///
  /// The articulated figure draws the upper and lower limb segments with this
  /// separation so the joints read as distinct parts rather than one tube.
  static const double jointGap = 0.016;

  /// Painter order (later entries are drawn on top and hit-tested first).
  static const List<BodySegment> drawOrder = [
    BodySegment.head,
    BodySegment.neck,
    BodySegment.chest,
    BodySegment.abdomen,
    BodySegment.leftUpperArm,
    BodySegment.rightUpperArm,
    BodySegment.leftForearm,
    BodySegment.rightForearm,
    BodySegment.leftThigh,
    BodySegment.rightThigh,
    BodySegment.leftCalf,
    BodySegment.rightCalf,
  ];

  // Normalised anatomy (units of height, x from centre).
  static const double _headY = 0.075;
  static const double _headRadius = 0.062;
  static const double _neckTop = 0.132;
  static const double _neckBottom = 0.166;
  static const double _neckHalf = 0.030;
  static const double _chestTop = 0.160;
  static const double _chestBottom = 0.400;
  static const double _chestTopHalf = 0.200;
  static const double _chestBottomHalf = 0.135;
  static const double _abdomenTop = 0.400;
  static const double _abdomenBottom = 0.550;
  static const double _abdomenBottomHalf = 0.155;
  static const double _armX = 0.235;
  static const double _upperArmTop = 0.185;
  static const double _upperArmBottom = 0.350;
  static const double _upperArmHalf = 0.052;
  static const double _forearmTop = _upperArmBottom + jointGap;
  static const double _forearmBottom = 0.545;
  static const double _forearmHalf = 0.045;
  static const double _legX = 0.075;
  static const double _thighTop = 0.548;
  static const double _thighBottom = 0.800;
  static const double _thighHalf = 0.075;
  static const double _calfTop = _thighBottom + jointGap;
  static const double _calfBottom = 0.970;
  static const double _calfHalf = 0.058;

  /// The largest aspect-preserving rectangle the figure fits into [size],
  /// centred inside it.
  static Rect figureRect(Size size) {
    var height = size.height;
    var width = height * figureAspectRatio;
    if (width > size.width) {
      width = size.width;
      height = width / figureAspectRatio;
    }
    return Rect.fromLTWH(
      (size.width - width) / 2,
      (size.height - height) / 2,
      width,
      height,
    );
  }

  /// Builds a canvas-space [Path] for every segment.
  ///
  /// [scaleFor] optionally returns a thickness multiplier per segment (used by
  /// body-composition projections); the default keeps the baseline build.
  static Map<BodySegment, Path> buildPaths(
    Size size, {
    double Function(BodySegment segment)? scaleFor,
  }) {
    final rect = figureRect(size);
    double scale(BodySegment segment) =>
        (scaleFor?.call(segment) ?? 1.0).clamp(0.5, 2.0);

    return {
      BodySegment.head: _ellipse(rect, 0, _headY, _headRadius),
      BodySegment.neck: _limb(
        rect,
        0,
        _neckTop,
        _neckBottom,
        _neckHalf,
        1,
      ),
      BodySegment.chest: _torso(
        rect,
        _chestTop,
        _chestBottom,
        _chestTopHalf,
        _chestBottomHalf,
        scale(BodySegment.chest),
      ),
      BodySegment.abdomen: _torso(
        rect,
        _abdomenTop,
        _abdomenBottom,
        _chestBottomHalf,
        _abdomenBottomHalf,
        scale(BodySegment.abdomen),
      ),
      BodySegment.leftUpperArm: _limb(
        rect,
        -_armX,
        _upperArmTop,
        _upperArmBottom,
        _upperArmHalf,
        scale(BodySegment.leftUpperArm),
      ),
      BodySegment.leftForearm: _limb(
        rect,
        -_armX,
        _forearmTop,
        _forearmBottom,
        _forearmHalf,
        scale(BodySegment.leftForearm),
      ),
      BodySegment.rightUpperArm: _limb(
        rect,
        _armX,
        _upperArmTop,
        _upperArmBottom,
        _upperArmHalf,
        scale(BodySegment.rightUpperArm),
      ),
      BodySegment.rightForearm: _limb(
        rect,
        _armX,
        _forearmTop,
        _forearmBottom,
        _forearmHalf,
        scale(BodySegment.rightForearm),
      ),
      BodySegment.leftThigh: _limb(
        rect,
        -_legX,
        _thighTop,
        _thighBottom,
        _thighHalf,
        scale(BodySegment.leftThigh),
      ),
      BodySegment.leftCalf: _limb(
        rect,
        -_legX,
        _calfTop,
        _calfBottom,
        _calfHalf,
        scale(BodySegment.leftCalf),
      ),
      BodySegment.rightThigh: _limb(
        rect,
        _legX,
        _thighTop,
        _thighBottom,
        _thighHalf,
        scale(BodySegment.rightThigh),
      ),
      BodySegment.rightCalf: _limb(
        rect,
        _legX,
        _calfTop,
        _calfBottom,
        _calfHalf,
        scale(BodySegment.rightCalf),
      ),
    };
  }

  /// A stable point inside [segment], used for hit tests and leader anchors.
  static Offset interiorPoint(BodySegment segment, Size size) {
    final rect = figureRect(size);
    return switch (segment) {
      BodySegment.head => _p(rect, 0, _headY),
      BodySegment.neck => _p(rect, 0, (_neckTop + _neckBottom) / 2),
      BodySegment.chest => _p(rect, 0, (_chestTop + _chestBottom) / 2),
      BodySegment.abdomen => _p(rect, 0, (_abdomenTop + _abdomenBottom) / 2),
      BodySegment.leftUpperArm =>
        _p(rect, -_armX, (_upperArmTop + _upperArmBottom) / 2),
      BodySegment.leftForearm =>
        _p(rect, -_armX, (_forearmTop + _forearmBottom) / 2),
      BodySegment.rightUpperArm =>
        _p(rect, _armX, (_upperArmTop + _upperArmBottom) / 2),
      BodySegment.rightForearm =>
        _p(rect, _armX, (_forearmTop + _forearmBottom) / 2),
      BodySegment.leftThigh =>
        _p(rect, -_legX, (_thighTop + _thighBottom) / 2),
      BodySegment.leftCalf => _p(rect, -_legX, (_calfTop + _calfBottom) / 2),
      BodySegment.rightThigh =>
        _p(rect, _legX, (_thighTop + _thighBottom) / 2),
      BodySegment.rightCalf => _p(rect, _legX, (_calfTop + _calfBottom) / 2),
    };
  }

  /// The point a callout leader line starts from (on [segment]).
  static Offset anchorFor(BodySegment segment, Size size) =>
      interiorPoint(segment, size);

  /// Resolves [position] to a segment using `Path.contains`, topmost first.
  static BodySegment? hitTest(
    Offset position,
    Size size, {
    double Function(BodySegment segment)? scaleFor,
  }) {
    final paths = buildPaths(size, scaleFor: scaleFor);
    for (final segment in drawOrder.reversed) {
      if (paths[segment]!.contains(position)) return segment;
    }
    return null;
  }

  static Offset _p(Rect rect, double ux, double uy) =>
      Offset(rect.center.dx + ux * rect.height, rect.top + uy * rect.height);

  static Path _ellipse(
    Rect rect,
    double ux,
    double uy,
    double radius,
  ) {
    final centre = _p(rect, ux, uy);
    final r = radius * rect.height;
    return Path()..addOval(Rect.fromCircle(center: centre, radius: r));
  }

  static Path _limb(
    Rect rect,
    double ux,
    double top,
    double bottom,
    double half,
    double scale,
  ) {
    final centre = _p(rect, ux, 0);
    final halfWidth = half * scale * rect.height;
    final r = Rect.fromLTRB(
      centre.dx - halfWidth,
      rect.top + top * rect.height,
      centre.dx + halfWidth,
      rect.top + bottom * rect.height,
    );
    return Path()
      ..addRRect(
        RRect.fromRectAndRadius(r, Radius.circular(halfWidth)),
      );
  }

  static Path _torso(
    Rect rect,
    double top,
    double bottom,
    double topHalf,
    double bottomHalf,
    double scale,
  ) {
    final topLeft = _p(rect, -topHalf * scale, top);
    final topRight = _p(rect, topHalf * scale, top);
    final bottomRight = _p(rect, bottomHalf * scale, bottom);
    final bottomLeft = _p(rect, -bottomHalf * scale, bottom);
    // M44 Task 1: organic (soft) sides. The side control points are pulled out
    // to the *wider* of the two half-widths at mid-height, so the chest and
    // abdomen read as anatomical volumes with a gentle convex bulge instead of
    // straight-sided trapezoids. The control never exceeds the wider baseline
    // half-width, so the path bounds (and every hit test) stay unchanged.
    final midY = (top + bottom) / 2;
    final bulgeHalf = (topHalf > bottomHalf ? topHalf : bottomHalf) * scale;
    final leftControl = _p(rect, -bulgeHalf, midY);
    final rightControl = _p(rect, bulgeHalf, midY);
    return Path()
      ..moveTo(topLeft.dx, topLeft.dy)
      ..quadraticBezierTo(
        leftControl.dx,
        leftControl.dy,
        bottomLeft.dx,
        bottomLeft.dy,
      )
      ..lineTo(bottomRight.dx, bottomRight.dy)
      ..quadraticBezierTo(
        rightControl.dx,
        rightControl.dy,
        topRight.dx,
        topRight.dy,
      )
      ..close();
  }
}
