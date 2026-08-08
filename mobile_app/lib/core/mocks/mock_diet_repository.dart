import '../data/diet_repository.dart';
import '../models/diet_models.dart';

const mockDailyMenus = <DailyMenu>[
  DailyMenu(
    id: 1,
    date: '2026-08-07',
    totalCalories: 2100,
    meals: [
      Meal(
        id: 101,
        name: 'Oatmeal with berries',
        mealType: MealType.breakfast,
        calories: 350,
        protein: 12,
        carbs: 55,
        fat: 8,
      ),
      Meal(
        id: 102,
        name: 'Grilled chicken salad',
        mealType: MealType.lunch,
        calories: 520,
        protein: 42,
        carbs: 30,
        fat: 22,
      ),
      Meal(
        id: 103,
        name: 'Salmon with quinoa',
        mealType: MealType.dinner,
        calories: 640,
        protein: 48,
        carbs: 52,
        fat: 24,
      ),
      Meal(
        id: 104,
        name: 'Greek yogurt & nuts',
        mealType: MealType.snack,
        calories: 590,
        protein: 18,
        carbs: 20,
        fat: 15,
      ),
    ],
  ),
  DailyMenu(
    id: 2,
    date: '2026-08-08',
    totalCalories: 1950,
    meals: [
      Meal(
        id: 201,
        name: 'Egg white omelette',
        mealType: MealType.breakfast,
        calories: 310,
        protein: 26,
        carbs: 12,
        fat: 16,
      ),
      Meal(
        id: 202,
        name: 'Turkey wrap',
        mealType: MealType.lunch,
        calories: 480,
        protein: 34,
        carbs: 48,
        fat: 14,
      ),
      Meal(
        id: 203,
        name: 'Beef stir-fry',
        mealType: MealType.dinner,
        calories: 610,
        protein: 52,
        carbs: 44,
        fat: 20,
      ),
      Meal(
        id: 204,
        name: 'Protein shake',
        mealType: MealType.snack,
        calories: 550,
        protein: 30,
        carbs: 15,
        fat: 6,
      ),
    ],
  ),
];

class MockDietRepository implements DietRepository {
  @override
  Future<List<DailyMenu>> getDailyMenus() {
    return Future.delayed(
      const Duration(milliseconds: 500),
      () => mockDailyMenus,
    );
  }
}
