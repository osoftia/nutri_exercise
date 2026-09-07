import '../data/meal_action_repository.dart';
import '../models/meal_action.dart';

/// In-memory [MealActionRepository] for tests.
class MockMealActionRepository implements MealActionRepository {
  final List<MealAction> _store = [];

  @override
  Future<void> logMeal(MealAction action) async {
    _store.add(action);
  }

  @override
  Future<List<MealAction>> getByDate(String date) async =>
      _store.where((action) => action.date == date).toList();

  @override
  Future<List<MealAction>> getAll() async => List.of(_store);
}