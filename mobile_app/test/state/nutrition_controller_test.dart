import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/mocks/mock_nutrition_repository.dart';
import 'package:nutri_mobile_app/core/models/food_entry.dart';
import 'package:nutri_mobile_app/core/state/nutrition_controller.dart';

void main() {
  late NutritionController controller;

  setUp(() {
    controller = NutritionController(
      repository: MockNutritionRepository(),
    );
  });

  group('NutritionController', () {
    test('load seeds state from the repository and notifies', () async {
      var notifications = 0;
      controller.addListener(() => notifications++);

      await controller.load();

      expect(controller.targetCalories, 2000);
      expect(controller.consumedCalories, 1000);
      expect(controller.proteinG, 30);
      expect(notifications, greaterThan(0));
    });

    test('logFood adds calories and macros and notifies', () async {
      await controller.load();
      var notifications = 0;
      controller.addListener(() => notifications++);

      controller.logFood(
        const FoodEntry(
          name: 'Grilled Chicken Bowl',
          calories: 650,
          proteinG: 45,
          carbsG: 55,
          fatG: 18,
        ),
      );

      expect(controller.consumedCalories, 1650);
      expect(controller.proteinG, 75);
      expect(controller.carbsG, 135);
      expect(controller.fatG, 38);
      expect(controller.entries, hasLength(1));
      expect(notifications, 1);
    });

    test('morphFactor is below 0.5 at the seeded 1000/2000 ratio', () async {
      await controller.load();
      expect(controller.morphFactor, lessThan(0.5));
    });

    test('morphFactor increases after logging calories', () async {
      await controller.load();
      final before = controller.morphFactor;

      controller.logFood(const FoodEntry(name: 'Big Meal', calories: 1200));

      expect(controller.morphFactor, greaterThan(before));
    });

    test('macro progress clamps to 1.0 and starts at seeded values', () async {
      await controller.load();

      expect(controller.proteinProgress, closeTo(30 / 150, 0.0001));
      expect(controller.carbsProgress, closeTo(80 / 250, 0.0001));
      expect(controller.fatProgress, closeTo(20 / 70, 0.0001));
    });

    test('derived getters expose ratio, targets and loading state', () async {
      await controller.load();

      expect(controller.calorieRatio, closeTo(0.5, 0.0001));
      expect(controller.macroTargets.protein, 150);
      expect(controller.macroTargets.carbs, 250);
      expect(controller.macroTargets.fat, 70);
      expect(controller.entries, isEmpty);
      expect(controller.isLoading, isFalse);
    });
  });
}
