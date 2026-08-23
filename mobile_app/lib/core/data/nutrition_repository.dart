import '../models/nutrition_state.dart';

/// Contract for reading and persisting a day's nutrition state.
abstract interface class NutritionRepository {
  /// Returns today's seeded/loaded nutrition state.
  Future<NutritionState> loadToday();

  /// Persists the given [state] (no-op for the mock implementation).
  Future<void> saveToday(NutritionState state);
}
