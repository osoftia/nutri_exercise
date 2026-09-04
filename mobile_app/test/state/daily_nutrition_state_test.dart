import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/models/log_parse_response.dart';
import 'package:nutri_mobile_app/core/state/daily_nutrition_state.dart';

void main() {
  group('DailyNutritionState', () {
    test('starts at zero totals', () {
      final state = DailyNutritionState();

      expect(state.calories, 0);
      expect(state.protein, 0);
      expect(state.carbs, 0);
      expect(state.fat, 0);
    });

    test('add accumulates calories and macros from a parse result', () {
      final state = DailyNutritionState();

      state.add(
        const LogParseResponse(
          calories: 650,
          protein: 45,
          carbs: 55,
          fat: 18,
        ),
      );
      state.add(
        const LogParseResponse(calories: 350, protein: 20, fat: 8),
      );

      expect(state.calories, 1000);
      expect(state.protein, 65);
      expect(state.carbs, 55);
      expect(state.fat, 26);
    });

    test('add ignores null macros', () {
      final state = DailyNutritionState();

      state.add(const LogParseResponse(calories: 120));

      expect(state.calories, 120);
      expect(state.protein, 0);
      expect(state.fat, 0);
    });

    test('reset clears every total and notifies', () {
      final state = DailyNutritionState()
        ..add(const LogParseResponse(calories: 500, protein: 10));
      var notifications = 0;
      state.addListener(() => notifications++);

      state.reset();

      expect(state.calories, 0);
      expect(state.protein, 0);
      expect(notifications, greaterThan(0));
    });

    test('add notifies listeners', () {
      final state = DailyNutritionState();
      var notifications = 0;
      state.addListener(() => notifications++);

      state.add(const LogParseResponse(calories: 100));

      expect(notifications, greaterThan(0));
    });
  });
}
