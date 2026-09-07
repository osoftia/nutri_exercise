import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/constants/meal_presets.dart';
import 'package:nutri_mobile_app/core/data/local_daily_log_repository.dart';
import 'package:nutri_mobile_app/core/database/database_helper.dart';
import 'package:nutri_mobile_app/core/mocks/mock_daily_log_repository.dart';
import 'package:nutri_mobile_app/core/models/diet_models.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

DatabaseHelper _buildHelper(Database db) => DatabaseHelper(database: db);

void main() {
  setUpAll(sqfliteFfiInit);

  group('defaultMealsByTimeOfDay', () {
    test('defines 3 defaults for each meal slot', () {
      for (final slot in ['breakfast', 'lunch', 'dinner']) {
        expect(defaultMealsByTimeOfDay[slot], hasLength(3));
      }
      expect(
        defaultMealsByTimeOfDay['breakfast'],
        ['Huevos con arepa', 'Avena', 'Frutas'],
      );
      expect(
        defaultMealsByTimeOfDay['lunch'],
        ['Pechuga con arroz', 'Pescado', 'Carne asada'],
      );
      expect(
        defaultMealsByTimeOfDay['dinner'],
        ['Ensalada', 'Sopa', 'Huevos cocidos'],
      );
    });
  });

  group('LocalDailyLogRepository.getTopMealsForTimeOfDay', () {
    late DatabaseHelper helper;
    late LocalDailyLogRepository repo;

    setUp(() async {
      final db = await databaseFactoryFfi.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: 1,
          singleInstance: false,
          onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
          onCreate: (db, version) async {
            await db.execute('''
              CREATE TABLE diets (
                id INTEGER PRIMARY KEY,
                date TEXT NOT NULL,
                total_calories INTEGER NOT NULL,
                meals_json TEXT NOT NULL
              )
            ''');
          },
        ),
      );
      helper = _buildHelper(db);
      repo = LocalDailyLogRepository(databaseHelper: helper);
    });

    Future<void> seedDiet(List<Map<String, Object?>> meals) async {
      await helper.upsertDiet(
        // ignore: prefer_const_constructors
        DailyMenu(
          id: 1,
          date: '2026-09-01',
          totalCalories: 2000,
          meals: meals
              .map(
                (m) => Meal(
                  id: m['id'] as int,
                  name: m['name'] as String,
                  mealType: MealType.values.byName(m['mealType'] as String),
                  calories: m['calories'] as int,
                  protein: 0,
                  carbs: 0,
                  fat: 0,
                ),
              )
              .toList(),
        ),
      );
    }

    test('returns defaults when there is no meal history', () async {
      final meals = await repo.getTopMealsForTimeOfDay('breakfast');

      expect(meals, ['Huevos con arepa', 'Avena', 'Frutas']);
    });

    test('returns the most frequent meals when history exists', () async {
      await seedDiet([
        {'id': 1, 'name': 'Pechuga con arroz', 'mealType': 'lunch', 'calories': 650},
        {'id': 2, 'name': 'Pescado', 'mealType': 'lunch', 'calories': 500},
        {'id': 3, 'name': 'Pechuga con arroz', 'mealType': 'lunch', 'calories': 650},
        {'id': 4, 'name': 'Carne asada', 'mealType': 'lunch', 'calories': 700},
      ]);

      final meals = await repo.getTopMealsForTimeOfDay('lunch');

      expect(meals, ['Pechuga con arroz', 'Pescado', 'Carne asada']);
    });

    test('only counts meals matching the requested time of day', () async {
      await seedDiet([
        {'id': 1, 'name': 'Pechuga con arroz', 'mealType': 'lunch', 'calories': 650},
        {'id': 2, 'name': 'Huevos con arepa', 'mealType': 'breakfast', 'calories': 400},
        {'id': 3, 'name': 'Pechuga con arroz', 'mealType': 'lunch', 'calories': 650},
      ]);

      final breakfast = await repo.getTopMealsForTimeOfDay('breakfast');

      expect(breakfast, ['Huevos con arepa']);
    });
  });

  group('MockDailyLogRepository.getTopMealsForTimeOfDay', () {
    test('returns defaults unless a custom seed is provided', () async {
      final repo = MockDailyLogRepository();

      expect(
        await repo.getTopMealsForTimeOfDay('dinner'),
        ['Ensalada', 'Sopa', 'Huevos cocidos'],
      );
    });

    test('honors a custom seed', () async {
      final repo = MockDailyLogRepository(
        topMeals: {'breakfast': ['Arepa', 'Perico']},
      );

      expect(await repo.getTopMealsForTimeOfDay('breakfast'), ['Arepa', 'Perico']);
    });
  });
}