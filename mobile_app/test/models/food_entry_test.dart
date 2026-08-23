import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/models/food_entry.dart';

void main() {
  group('FoodEntry', () {
    test('constructs with calories and optional macros', () {
      const entry = FoodEntry(
        name: 'Grilled Chicken Bowl',
        calories: 650,
        proteinG: 45,
        carbsG: 55,
        fatG: 18,
      );
      expect(entry.name, 'Grilled Chicken Bowl');
      expect(entry.calories, 650);
      expect(entry.proteinG, 45);
      expect(entry.carbsG, 55);
      expect(entry.fatG, 18);
    });

    test('macros default to zero when omitted', () {
      const entry = FoodEntry(name: 'Banana', calories: 120);
      expect(entry.proteinG, 0);
      expect(entry.carbsG, 0);
      expect(entry.fatG, 0);
    });
  });

  group('MacroTargets', () {
    test('daily defaults expose 150/250/70 grams', () {
      expect(MacroTargets.daily.protein, 150);
      expect(MacroTargets.daily.carbs, 250);
      expect(MacroTargets.daily.fat, 70);
    });
  });
}
