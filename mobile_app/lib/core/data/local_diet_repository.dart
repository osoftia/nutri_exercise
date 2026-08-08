import 'dart:convert';

import '../database/database_helper.dart';
import '../mocks/mock_diet_repository.dart';
import '../models/diet_models.dart';
import 'diet_repository.dart';

class LocalDietRepository implements DietRepository {
  LocalDietRepository({DatabaseHelper? databaseHelper})
    : _databaseHelper = databaseHelper ?? DatabaseHelper();

  final DatabaseHelper _databaseHelper;
  bool _seeded = false;

  @override
  Future<List<DailyMenu>> getDailyMenus() async {
    await _seedIfNeeded();
    final rows = await _databaseHelper.getDiets();
    return rows.map((row) {
      return DailyMenu(
        id: row['id'] as int,
        date: row['date'] as String,
        totalCalories: row['total_calories'] as int,
        meals: (jsonDecode(row['meals_json'] as String) as List<dynamic>)
            .map((meal) => Meal.fromJson(meal as Map<String, dynamic>))
            .toList(),
      );
    }).toList();
  }

  Future<void> saveDiet(DailyMenu menu) async {
    await _seedIfNeeded();
    await _databaseHelper.upsertDiet(menu);
  }

  Future<void> _seedIfNeeded() async {
    if (_seeded) return;
    final rows = await _databaseHelper.getDiets();
    if (rows.isEmpty) {
      for (final menu in mockDailyMenus) {
        await _databaseHelper.upsertDiet(menu);
      }
    }
    _seeded = true;
  }
}
