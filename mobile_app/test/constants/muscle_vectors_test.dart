import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/constants/muscle_vectors.dart';

void main() {
  group('muscleRegions', () {
    test('splits arms into Upper Arms and Forearms', () {
      final ids = muscleRegions.map((r) => r.id).toSet();

      expect(ids, contains('upper_arms'));
      expect(ids, contains('forearms'));
      expect(ids, isNot(contains('arms')));
    });

    test('splits legs into Thighs and Calves', () {
      final ids = muscleRegions.map((r) => r.id).toSet();

      expect(ids, contains('thighs'));
      expect(ids, contains('calves'));
      expect(ids, isNot(contains('legs')));
    });

    test('keeps the torso regions', () {
      final ids = muscleRegions.map((r) => r.id).toSet();

      expect(ids, containsAll(['chest', 'abs', 'shoulders', 'back']));
    });

    test('registers the fine regions on both the front and back views', () {
      final byId = <String, Set<MuscleView>>{};
      for (final region in muscleRegions) {
        byId.putIfAbsent(region.id, () => {}).add(region.view);
      }

      for (final id in ['upper_arms', 'forearms', 'thighs', 'calves']) {
        expect(byId[id], containsAll([MuscleView.front, MuscleView.back]));
      }
    });
  });
}