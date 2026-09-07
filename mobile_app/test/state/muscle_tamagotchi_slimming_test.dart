import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/state/muscle_tamagotchi_state.dart';

void main() {
  group('MuscleTamagotchiState slimming effect', () {
    test('logging an exercise reduces accumulated core fullness', () {
      final state = MuscleTamagotchiState()..applyNutrition(2000);
      final fullnessBefore = state.coreFullness;

      state.applySlimming();

      expect(state.coreFullness, lessThan(fullnessBefore));
    });

    test('slimming shrinks the settled core scale (width)', () {
      final state = MuscleTamagotchiState()..applyNutrition(2000);
      final widthBefore = state.settledCoreScale();

      state.applySlimming();

      expect(state.settledCoreScale(), lessThan(widthBefore));
    });

    test('slimming clears any transient bloat', () {
      final state = MuscleTamagotchiState()..applyNutrition(500);

      expect(state.coreIsBloating, isTrue);

      state.applySlimming();

      expect(state.coreIsBloating, isFalse);
    });

    test('slimming never drops core fullness below zero', () {
      final state = MuscleTamagotchiState();

      state.applySlimming();

      expect(state.coreFullness, 0.0);
    });

    test('slimming counteracts the expansion from eating', () {
      final ate = MuscleTamagotchiState()..applyNutrition(2000);
      final trained = MuscleTamagotchiState()
        ..applyNutrition(2000)
        ..applySlimming();

      expect(trained.coreFullness, lessThan(ate.coreFullness));
    });
  });
}