import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/domain/body_projection/body_segment.dart';
import 'package:nutri_mobile_app/ui/organisms/body_blueprint/body_segment_geometry.dart';

const _size = Size(720, 420);

Rect _boundsOf(BodySegment segment, [Map<BodySegment, Path>? paths]) =>
    (paths ?? BodySegmentGeometry.buildPaths(_size))[segment]!.getBounds();

void main() {
  group('M44 exact avatar silhouette', () {
    final figure = BodySegmentGeometry.figureRect(_size);
    final paths = BodySegmentGeometry.buildPaths(_size);

    test('limbs are slimmer than half a chest width', () {
      final chest = _boundsOf(BodySegment.chest, paths).width;
      for (final segment in [
        BodySegment.leftUpperArm,
        BodySegment.rightUpperArm,
        BodySegment.leftForearm,
        BodySegment.rightForearm,
        BodySegment.leftThigh,
        BodySegment.rightThigh,
        BodySegment.leftCalf,
        BodySegment.rightCalf,
      ]) {
        expect(
          _boundsOf(segment, paths).width,
          lessThan(chest * 0.5),
          reason: '${segment.name} should read as slim',
        );
      }
    });

    test('each limb sits within its documented slim envelope', () {
      final height = figure.height;
      // Normalized half-widths: arms 0.042/0.034, legs 0.062/0.046.
      expect(
        _boundsOf(BodySegment.leftUpperArm, paths).width,
        closeTo(2 * 0.042 * height, 0.5),
      );
      expect(
        _boundsOf(BodySegment.leftForearm, paths).width,
        closeTo(2 * 0.034 * height, 0.5),
      );
      expect(
        _boundsOf(BodySegment.leftThigh, paths).width,
        closeTo(2 * 0.062 * height, 0.5),
      );
      expect(
        _boundsOf(BodySegment.leftCalf, paths).width,
        closeTo(2 * 0.046 * height, 0.5),
      );
    });

    test('limbs are slimmer than the previous silhouette', () {
      final height = figure.height;
      // Previous half-widths: arms 0.052/0.045, legs 0.075/0.058.
      expect(
        _boundsOf(BodySegment.leftUpperArm, paths).width,
        lessThan(2 * 0.052 * height),
      );
      expect(
        _boundsOf(BodySegment.leftForearm, paths).width,
        lessThan(2 * 0.045 * height),
      );
      expect(
        _boundsOf(BodySegment.leftThigh, paths).width,
        lessThan(2 * 0.075 * height),
      );
      expect(
        _boundsOf(BodySegment.leftCalf, paths).width,
        lessThan(2 * 0.058 * height),
      );
    });

    test('elbows and knees keep a clean articulated gap', () {
      final gap = BodySegmentGeometry.jointGap * figure.height;
      for (final pair in [
        (BodySegment.leftUpperArm, BodySegment.leftForearm),
        (BodySegment.rightUpperArm, BodySegment.rightForearm),
        (BodySegment.leftThigh, BodySegment.leftCalf),
        (BodySegment.rightThigh, BodySegment.rightCalf),
      ]) {
        final upper = _boundsOf(pair.$1, paths);
        final lower = _boundsOf(pair.$2, paths);
        expect(lower.top - upper.bottom, closeTo(gap, 0.001));
        expect(upper.overlaps(lower), isFalse);
      }
    });

    test('the torso is drawn as a valid closed contour', () {
      for (final segment in [BodySegment.chest, BodySegment.abdomen]) {
        final path = paths[segment]!;
        final metrics = path.computeMetrics().first;
        expect(metrics.isClosed, isTrue);
        expect(
          metrics.length,
          greaterThan(2 * _boundsOf(segment, paths).height),
        );
        // The contour is hit-testable at its own centre.
        expect(
          path.contains(
            BodySegmentGeometry.interiorPoint(segment, _size),
          ),
          isTrue,
        );
      }
    });
  });
}
