import '../data/nutrition_repository.dart';
import '../models/food_entry.dart';
import '../models/nutrition_state.dart';

/// In-memory test double seeded with a deterministic baseline so dashboard and
/// avatar morph assertions are reproducible.
class MockNutritionRepository implements NutritionRepository {
  MockNutritionRepository({NutritionState? initialState})
    : _state = initialState ?? seed;

  static const NutritionState seed = NutritionState(
    targetCalories: 2000,
    consumedCalories: 1000,
    proteinG: 30,
    carbsG: 80,
    fatG: 20,
    entries: [],
    weeklyCalories: [1800, 1500, 1200, 2000, 1750, 2400, 1450],
    macroTargets: MacroTargets.daily,
  );

  NutritionState _state;

  @override
  Future<NutritionState> loadToday() async => _state;

  @override
  Future<void> saveToday(NutritionState state) async {
    _state = state;
  }
}
