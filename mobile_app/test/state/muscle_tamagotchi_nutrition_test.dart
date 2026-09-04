import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/state/muscle_tamagotchi_state.dart';

void main() {
  group('MuscleTamagotchiState nutrition reaction', () {
    test('a fresh state has zero core fullness and is not bloating', () {
      final state = MuscleTamagotchiState();

      expect(state.coreFullness, 0.0);
      expect(state.coreIsBloating, isFalse);
    });

    test('applyNutrition raises core fullness in proportion to calories', () {
      final state = MuscleTamagotchiState();

      state.applyNutrition(2000);

      expect(state.coreFullness, greaterThan(0.0));
      expect(state.coreFullness, lessThanOrEqualTo(1.0));
    });

    test('applyNutrition sets the transient bloat flag', () {
      final state = MuscleTamagotchiState();

      state.applyNutrition(500);

      expect(state.coreIsBloating, isTrue);
    });

    test('settleCore clears the bloat flag but keeps the fullness', () {
      final state = MuscleTamagotchiState()
        ..applyNutrition(800);
      final fullnessBefore = state.coreFullness;

      state.settleCore();

      expect(state.coreIsBloating, isFalse);
      expect(state.coreFullness, fullnessBefore);
    });

    test('fullness accumulates — 1000 kcal settles larger than 400 kcal', () {
      final low = MuscleTamagotchiState()..applyNutrition(400);
      final high = MuscleTamagotchiState()
        ..applyNutrition(400)
        ..applyNutrition(600);

      expect(high.coreFullness, greaterThan(low.coreFullness));
    });

    test('settled core scale grows with fullness and never shrinks below 1.0', () {
      final state = MuscleTamagotchiState();

      expect(state.settledCoreScale(), 1.0);

      state.applyNutrition(3000);
      final larger = state.settledCoreScale();

      expect(larger, greaterThanOrEqualTo(1.0));
    });

    test('fullness clamps at 1.0', () {
      final state = MuscleTamagotchiState();

      state.applyNutrition(999999);

      expect(state.coreFullness, 1.0);
    });
  });
}
