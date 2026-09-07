import '../database/database_helper.dart';
import '../models/meal_action.dart';
import 'meal_action_repository.dart';

/// SQLite-backed [MealActionRepository].
class LocalMealActionRepository implements MealActionRepository {
  LocalMealActionRepository({DatabaseHelper? databaseHelper})
    : _databaseHelper = databaseHelper ?? DatabaseHelper();

  final DatabaseHelper _databaseHelper;

  @override
  Future<void> logMeal(MealAction action) =>
      _databaseHelper.insertMealAction(action);

  @override
  Future<List<MealAction>> getByDate(String date) async {
    final rows = await _databaseHelper.getMealActionsByDate(date);
    return rows.map(MealAction.fromMap).toList();
  }

  @override
  Future<List<MealAction>> getAll() async {
    final rows = await _databaseHelper.getAllMealActions();
    return rows.map(MealAction.fromMap).toList();
  }
}