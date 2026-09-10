import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/models/log_parse_response.dart';
import 'package:nutri_mobile_app/core/state/muscle_tamagotchi_state.dart';

void main() {
  group('food flash debug (M35)', () {
    test('fresh state has no meals and no flash', () {
      final state = MuscleTamagotchiState();
      expect(state.mealCount, 0);
      expect(state.lastMealAt, isNull);
      expect(
        MuscleTamagotchiState.foodFlashActiveSince(
          state.lastMealAt,
          DateTime.now(),
        ),
        isFalse,
      );
    });

    test('applyMeal bumps the meal counter and timestamps the meal', () {
      final state = MuscleTamagotchiState();
      const meal = LogParseResponse(calories: 650, protein: 45, fat: 18);
      state.applyMeal(meal);
      expect(state.mealCount, 1);
      expect(state.lastMealAt, isNotNull);
      state.applyMeal(meal);
      expect(state.mealCount, 2);
    });

    test('applyNutrition bumps the meal counter too', () {
      final state = MuscleTamagotchiState();
      state.applyNutrition(500);
      expect(state.mealCount, 1);
      expect(state.lastMealAt, isNotNull);
    });

    test('flash is active within 2 s and expired afterwards', () {
      final at = DateTime(2026, 9, 10, 12, 0, 0);
      expect(
        MuscleTamagotchiState.foodFlashActiveSince(
          at,
          at.add(const Duration(milliseconds: 1999)),
        ),
        isTrue,
      );
      expect(
        MuscleTamagotchiState.foodFlashActiveSince(
          at,
          at.add(const Duration(seconds: 2)),
        ),
        isFalse,
      );
      expect(
        MuscleTamagotchiState.foodFlashActiveSince(
          at,
          at.add(const Duration(seconds: 30)),
        ),
        isFalse,
      );
    });

    test('food logs notify listeners', () {
      final state = MuscleTamagotchiState();
      var notified = 0;
      state.addListener(() => notified++);
      state.applyMeal(
        const LogParseResponse(calories: 650, protein: 45, fat: 18),
      );
      expect(notified, greaterThan(0));
    });
  });
}
