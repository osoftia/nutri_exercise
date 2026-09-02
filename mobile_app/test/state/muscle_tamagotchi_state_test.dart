import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/state/muscle_tamagotchi_state.dart';

void main() {
  group('MuscleTamagotchiState baseline', () {
    test('starts every group at 0.5', () {
      final state = MuscleTamagotchiState();

      for (final group in MuscleTamagotchiGroup.values) {
        expect(state.massOf(group), 0.5);
      }
    });

    test('clamps initial mass into the valid range', () {
      final state = MuscleTamagotchiState(
        initialMass: {
          MuscleTamagotchiGroup.chest: 1.4,
          MuscleTamagotchiGroup.legs: -0.2,
        },
      );

      expect(state.massOf(MuscleTamagotchiGroup.chest), 1.0);
      expect(state.massOf(MuscleTamagotchiGroup.legs), 0.0);
    });
  });

  group('MuscleTamagotchiState growth', () {
    test('grows only the targeted groups', () {
      final state = MuscleTamagotchiState();

      state.applyGrowth([MuscleTamagotchiGroup.chest]);

      expect(state.massOf(MuscleTamagotchiGroup.chest), greaterThan(0.5));
      expect(state.massOf(MuscleTamagotchiGroup.core), 0.5);
      expect(state.massOf(MuscleTamagotchiGroup.arms), 0.5);
      expect(state.massOf(MuscleTamagotchiGroup.legs), 0.5);
    });

    test('adds the growth delta to the current mass', () {
      final state = MuscleTamagotchiState(growthDelta: 0.1);

      state.applyGrowth([MuscleTamagotchiGroup.arms]);

      expect(state.massOf(MuscleTamagotchiGroup.arms), closeTo(0.6, 0.0001));
    });

    test('clamps growth at 1.0', () {
      final state = MuscleTamagotchiState(
        initialMass: {MuscleTamagotchiGroup.chest: 0.95},
      );

      state.applyGrowth([MuscleTamagotchiGroup.chest]);

      expect(state.massOf(MuscleTamagotchiGroup.chest), 1.0);
    });

    test('notifies listeners on growth', () {
      final state = MuscleTamagotchiState();
      var notified = false;
      state.addListener(() => notified = true);

      state.applyGrowth([MuscleTamagotchiGroup.legs]);

      expect(notified, isTrue);
    });
  });

  group('MuscleTamagotchiState decay', () {
    test('reduces mass over an inactive period', () {
      final state = MuscleTamagotchiState(
        initialMass: {MuscleTamagotchiGroup.arms: 0.8},
      );

      state.applyDecay(const Duration(days: 1));

      expect(state.massOf(MuscleTamagotchiGroup.arms), lessThan(0.8));
    });

    test('scales decay with the elapsed time', () {
      final state = MuscleTamagotchiState(decayPerDay: 0.05);

      state.applyDecay(const Duration(days: 2));

      // 0.5 - (0.05 * 2) = 0.4
      expect(state.massOf(MuscleTamagotchiGroup.core), closeTo(0.4, 0.0001));
    });

    test('clamps decay at 0.0', () {
      final state = MuscleTamagotchiState(
        initialMass: {MuscleTamagotchiGroup.legs: 0.02},
      );

      state.applyDecay(const Duration(days: 1));

      expect(state.massOf(MuscleTamagotchiGroup.legs), 0.0);
    });

    test('notifies listeners on decay', () {
      final state = MuscleTamagotchiState();
      var notified = false;
      state.addListener(() => notified = true);

      state.applyDecay(const Duration(days: 1));

      expect(notified, isTrue);
    });
  });

  group('MuscleTamagotchiState tiers', () {
    test('maps low mass to tier C', () {
      final state = MuscleTamagotchiState(
        initialMass: {MuscleTamagotchiGroup.legs: 0.1},
      );

      expect(state.tierOf(MuscleTamagotchiGroup.legs), MuscleTier.c);
    });

    test('maps mid mass to tier B', () {
      final state = MuscleTamagotchiState(
        initialMass: {MuscleTamagotchiGroup.arms: 0.5},
      );

      expect(state.tierOf(MuscleTamagotchiGroup.arms), MuscleTier.b);
    });

    test('maps high mass to tier A', () {
      final state = MuscleTamagotchiState(
        initialMass: {MuscleTamagotchiGroup.core: 0.75},
      );

      expect(state.tierOf(MuscleTamagotchiGroup.core), MuscleTier.a);
    });

    test('maps peak mass to tier S', () {
      final state = MuscleTamagotchiState(
        initialMass: {MuscleTamagotchiGroup.chest: 0.95},
      );

      expect(state.tierOf(MuscleTamagotchiGroup.chest), MuscleTier.s);
    });

    test('baseline mass maps to tier B', () {
      final state = MuscleTamagotchiState();

      expect(state.tierOf(MuscleTamagotchiGroup.core), MuscleTier.b);
    });
  });
}
