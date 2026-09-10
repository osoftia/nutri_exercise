import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/constants/muscle_vectors.dart';
import 'package:nutri_mobile_app/ui/organisms/interactive_body_map.dart';

const _testSize = Size(320, 200);

Rect _boundsOf(String id, MuscleView view) {
  final region = muscleRegions.firstWhere(
    (r) => r.id == id && r.view == view,
  );
  return region.normalizedPath.getBounds();
}

void main() {
  group('strict split-limb gaps (M35)', () {
    test('upper arms and forearms have disjoint bounding boxes', () {
      for (final view in MuscleView.values) {
        final upper = _boundsOf('upper_arms', view);
        final fore = _boundsOf('forearms', view);
        expect(upper.overlaps(fore), isFalse, reason: '$view arm gap');
        expect(upper.bottom, lessThan(fore.top), reason: '$view arm order');
      }
    });

    test('thighs and calves have disjoint bounding boxes', () {
      for (final view in MuscleView.values) {
        final thigh = _boundsOf('thighs', view);
        final calf = _boundsOf('calves', view);
        expect(thigh.overlaps(calf), isFalse, reason: '$view leg gap');
        expect(thigh.bottom, lessThan(calf.top), reason: '$view leg order');
      }
    });

    test('pinned taps still resolve to their gapped segments', () {
      expect(muscleAt(const Offset(46.0, 63.6), _testSize)?.id, 'upper_arms');
      expect(muscleAt(const Offset(46.0, 95.6), _testSize)?.id, 'forearms');
      expect(muscleAt(const Offset(75.1, 133.5), _testSize)?.id, 'thighs');
      expect(muscleAt(const Offset(70.8, 153.9), _testSize)?.id, 'calves');
      expect(muscleAt(const Offset(201.2, 63.6), _testSize)?.id, 'upper_arms');
      expect(muscleAt(const Offset(201.2, 95.6), _testSize)?.id, 'forearms');
      expect(muscleAt(const Offset(230.3, 133.5), _testSize)?.id, 'thighs');
      expect(muscleAt(const Offset(225.9, 153.9), _testSize)?.id, 'calves');
    });
  });
}
