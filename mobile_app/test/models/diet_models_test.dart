import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/models/diet_models.dart';

void main() {
  group('Meal', () {
    test('fromJson and toJson round-trip', () {
      const meal = Meal(
        id: 1,
        name: 'Oatmeal',
        mealType: MealType.breakfast,
        calories: 420,
        protein: 15,
        carbs: 60,
        fat: 12,
      );
      final restored = Meal.fromJson(meal.toJson());
      expect(restored.id, 1);
      expect(restored.name, 'Oatmeal');
      expect(restored.mealType, MealType.breakfast);
      expect(restored.calories, 420);
      expect(restored.protein, 15);
      expect(restored.carbs, 60);
      expect(restored.fat, 12);
    });
  });

  group('DailyMenu', () {
    test('fromJson and toJson round-trip', () {
      const menu = DailyMenu(
        id: 1,
        date: '2026-08-07',
        totalCalories: 2000,
        meals: [
          Meal(
            id: 1,
            name: 'Lunch',
            mealType: MealType.lunch,
            calories: 650,
            protein: 45,
            carbs: 55,
            fat: 18,
          ),
        ],
      );
      final restored = DailyMenu.fromJson(menu.toJson());
      expect(restored.id, 1);
      expect(restored.date, '2026-08-07');
      expect(restored.totalCalories, 2000);
      expect(restored.meals, hasLength(1));
      expect(restored.meals.first.name, 'Lunch');
    });
  });
}
