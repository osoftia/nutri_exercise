import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/models/log_parse_response.dart';
import 'package:nutri_mobile_app/core/state/muscle_tamagotchi_state.dart';

int notificationsFor(
  MuscleTamagotchiState state,
  void Function() action,
) {
  var count = 0;
  void listener() => count++;
  state.addListener(listener);
  action();
  state.removeListener(listener);
  return count;
}

void main() {
  group('food logs notify exactly once', () {
    test('applyNutrition notifies and starts the bloat', () {
      final state = MuscleTamagotchiState();

      expect(notificationsFor(state, () => state.applyNutrition(600)), 1);
      expect(state.coreIsBloating, isTrue);
    });

    test('applyMeal with a healthy meal notifies via growth', () {
      final state = MuscleTamagotchiState();
      const meal = LogParseResponse(calories: 500, protein: 40, fat: 10);

      expect(notificationsFor(state, () => state.applyMeal(meal)), 1);
      expect(state.coreIsBloating, isFalse);
    });

    test('applyMeal with an unhealthy meal notifies via bloat', () {
      final state = MuscleTamagotchiState();
      const meal = LogParseResponse(calories: 900, protein: 5, fat: 60);

      expect(notificationsFor(state, () => state.applyMeal(meal)), 1);
      expect(state.coreIsBloating, isTrue);
    });
  });

  group('exercise logs notify and clear bloat', () {
    test('applySlimming notifies and clears the bloat flag', () {
      final state = MuscleTamagotchiState()..applyNutrition(600);

      expect(notificationsFor(state, state.applySlimming), 1);
      expect(state.coreIsBloating, isFalse);
    });

    test('applyGrowth notifies', () {
      final state = MuscleTamagotchiState();

      expect(
        notificationsFor(
          state,
          () => state.applyGrowth(const [MuscleTamagotchiGroup.arms]),
        ),
        1,
      );
    });

    test('applyDecay notifies', () {
      final state = MuscleTamagotchiState();

      expect(
        notificationsFor(
          state,
          () => state.applyDecay(const Duration(hours: 12)),
        ),
        1,
      );
    });
  });

  group('override changes notify', () {
    test('setOverrides notifies', () {
      final state = MuscleTamagotchiState();

      expect(
        notificationsFor(
          state,
          () => state.setOverrides(const {'chest': Colors.red}),
        ),
        1,
      );
    });

    test('clearOverrides notifies only when overrides exist', () {
      final state = MuscleTamagotchiState();

      expect(notificationsFor(state, state.clearOverrides), 0);

      state.setOverrides(const {'chest': Colors.red});
      expect(notificationsFor(state, state.clearOverrides), 1);
    });
  });

  group('settling stays quiet unless bloating', () {
    test('settleCore notifies only while bloating', () {
      final state = MuscleTamagotchiState();

      expect(notificationsFor(state, state.settleCore), 0);

      state.applyNutrition(600);
      expect(notificationsFor(state, state.settleCore), 1);
      expect(state.coreIsBloating, isFalse);
    });
  });
}
