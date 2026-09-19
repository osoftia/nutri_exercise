import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/domain/body_projection/body_segment.dart';
import 'package:nutri_mobile_app/ui/organisms/body_blueprint/body_segment_geometry.dart';

void main() {
  const size = Size(720, 420);

  group('M37 body segment geometry', () {
    final paths = BodySegmentGeometry.buildPaths(size);

    test('lays out a path for every one of the twelve segments', () {
      expect(paths.length, BodySegment.values.length);
      expect(paths.keys.toSet(), BodySegment.values.toSet());
    });

    test('arms and legs connect at the elbow and knee', () {
      final leftArmUpper = paths[BodySegment.leftUpperArm]!.getBounds();
      final leftArmLower = paths[BodySegment.leftForearm]!.getBounds();
      expect(leftArmUpper.bottom, greaterThanOrEqualTo(leftArmLower.top));

      final rightArmUpper = paths[BodySegment.rightUpperArm]!.getBounds();
      final rightArmLower = paths[BodySegment.rightForearm]!.getBounds();
      expect(rightArmUpper.bottom, greaterThanOrEqualTo(rightArmLower.top));

      final leftLegUpper = paths[BodySegment.leftThigh]!.getBounds();
      final leftLegLower = paths[BodySegment.leftCalf]!.getBounds();
      expect(leftLegUpper.bottom, greaterThanOrEqualTo(leftLegLower.top));

      final rightLegUpper = paths[BodySegment.rightThigh]!.getBounds();
      final rightLegLower = paths[BodySegment.rightCalf]!.getBounds();
      expect(rightLegUpper.bottom, greaterThanOrEqualTo(rightLegLower.top));
    });

    test('the torso chain is connected at the neck and hips', () {
      final head = paths[BodySegment.head]!.getBounds();
      final neck = paths[BodySegment.neck]!.getBounds();
      final chest = paths[BodySegment.chest]!.getBounds();
      final abdomen = paths[BodySegment.abdomen]!.getBounds();
      final thigh = paths[BodySegment.leftThigh]!.getBounds();

      expect(neck.top, lessThanOrEqualTo(head.bottom));
      expect(chest.top, lessThanOrEqualTo(neck.bottom));
      expect(thigh.top, lessThanOrEqualTo(abdomen.bottom));
    });

    test('the shoulders connect the arms to the chest', () {
      final arm = paths[BodySegment.leftUpperArm]!.getBounds();
      final chest = paths[BodySegment.chest]!.getBounds();
      expect(arm.overlaps(chest), isTrue);
    });

    test('keeps the figure aspect ratio at any width', () {
      final wide = BodySegmentGeometry.figureRect(const Size(300, 400));
      final tall = BodySegmentGeometry.figureRect(const Size(600, 800));
      expect(
        wide.width / wide.height,
        closeTo(tall.width / tall.height, 0.001),
      );
    });

    test('hit test resolves the centre of every segment', () {
      for (final segment in BodySegment.values) {
        final centre = BodySegmentGeometry.interiorPoint(segment, size);
        expect(
          BodySegmentGeometry.hitTest(centre, size),
          segment,
          reason: 'centre of ${segment.name} must hit ${segment.name}',
        );
      }
    });

    test('hit test returns null outside the figure', () {
      expect(BodySegmentGeometry.hitTest(const Offset(1, 1), size), isNull);
      expect(
        BodySegmentGeometry.hitTest(const Offset(719, 419), size),
        isNull,
      );
    });

    test('callout anchors sit inside their own segment', () {
      for (final slot in [
        BodySegment.leftUpperArm,
        BodySegment.abdomen,
        BodySegment.leftThigh,
        BodySegment.chest,
        BodySegment.rightUpperArm,
        BodySegment.rightThigh,
      ]) {
        final path = paths[slot]!;
        final anchor = BodySegmentGeometry.anchorFor(slot, size);
        expect(path.contains(anchor), isTrue, reason: 'anchor for ${slot.name}');
      }
    });

    test('draw order covers every segment exactly once', () {
      expect(
        BodySegmentGeometry.drawOrder.toSet(),
        BodySegment.values.toSet(),
      );
      expect(BodySegmentGeometry.drawOrder.length, BodySegment.values.length);
    });

    test('clamps the figure width on a very narrow canvas', () {
      final rect = BodySegmentGeometry.figureRect(const Size(100, 800));
      expect(rect.width, closeTo(100, 0.001));
      expect(
        rect.height,
        closeTo(100 / BodySegmentGeometry.figureAspectRatio, 0.001),
      );
    });

    test('projection scale widens only the selected segment', () {
      final normal =
          BodySegmentGeometry.buildPaths(size)[BodySegment.chest]!.getBounds();
      final scaled = BodySegmentGeometry.buildPaths(
        size,
        scaleFor: (segment) => segment == BodySegment.chest ? 1.5 : 1.0,
      )[BodySegment.chest]!.getBounds();
      expect(scaled.width, greaterThan(normal.width));
      expect(scaled.left, lessThan(normal.left));
      expect(scaled.right, greaterThan(normal.right));
    });
  });
}
