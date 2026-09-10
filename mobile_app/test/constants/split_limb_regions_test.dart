import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/constants/muscle_vectors.dart';

void main() {
  group('split limb regions', () {
    test('split set contains exactly the four limb segments', () {
      expect(
        splitLimbRegionIds,
        {'upper_arms', 'forearms', 'thighs', 'calves'},
      );
    });

    test('isSplitLimbRegion matches only split segments', () {
      for (final id in splitLimbRegionIds) {
        expect(isSplitLimbRegion(id), isTrue, reason: id);
      }
      for (final id in ['chest', 'abs', 'shoulders', 'back']) {
        expect(isSplitLimbRegion(id), isFalse, reason: id);
      }
    });

    test('every split id resolves to a registered region', () {
      final ids = muscleRegions.map((r) => r.id).toSet();
      expect(ids, containsAll(splitLimbRegionIds));
    });
  });
}
