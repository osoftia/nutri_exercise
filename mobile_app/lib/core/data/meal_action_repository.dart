import '../models/meal_action.dart';

/// Contract for persisting meals quick-logged from notification actions.
abstract interface class MealActionRepository {
  /// Persists [action].
  Future<void> logMeal(MealAction action);

  /// Returns every meal logged for [date].
  Future<List<MealAction>> getByDate(String date);

  /// Returns every logged meal, newest first.
  Future<List<MealAction>> getAll();
}