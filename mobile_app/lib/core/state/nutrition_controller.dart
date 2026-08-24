import 'package:flutter/foundation.dart';

import '../data/nutrition_repository.dart';
import '../models/body_morph.dart';
import '../models/food_entry.dart';
import '../models/nutrition_state.dart';

/// ChangeNotifier owning the nutrition state for a single day. Every mutator
/// notifies listeners so charts and the dynamic avatar update on the same
/// frame.
class NutritionController extends ChangeNotifier {
  NutritionController({required NutritionRepository repository})
    : _repository = repository;

  final NutritionRepository _repository;

  NutritionState? _state;
  bool _isLoading = false;

  int get targetCalories => _state?.targetCalories ?? 2000;
  int get consumedCalories => _state?.consumedCalories ?? 0;
  int get proteinG => _state?.proteinG ?? 0;
  int get carbsG => _state?.carbsG ?? 0;
  int get fatG => _state?.fatG ?? 0;
  List<FoodEntry> get entries => _state?.entries ?? const [];
  List<int> get weeklyCalories => _state?.weeklyCalories ?? const [];
  bool get isLoading => _isLoading;

  MacroTargets get macroTargets => _state?.macroTargets ?? MacroTargets.daily;

  /// consumed / target (guards divide-by-zero).
  double get calorieRatio =>
      targetCalories == 0 ? 0 : consumedCalories / targetCalories;

  /// Normalized morph factor driving the dynamic avatar shape.
  double get morphFactor => morphFactorFor(consumedCalories, targetCalories);

  double get proteinProgress => _progress(proteinG, macroTargets.protein);
  double get carbsProgress => _progress(carbsG, macroTargets.carbs);
  double get fatProgress => _progress(fatG, macroTargets.fat);

  static double _progress(int consumed, int target) =>
      target == 0 ? 0.0 : (consumed / target).clamp(0.0, 1.0);

  /// Seeds state from the repository and notifies.
  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    _state = await _repository.loadToday();
    _isLoading = false;
    notifyListeners();
  }

  /// Adds [entry]'s calories and macros to the day and notifies.
  void logFood(FoodEntry entry) {
    final s = _state ??
        const NutritionState(
          targetCalories: 2000,
          consumedCalories: 0,
          proteinG: 0,
          carbsG: 0,
          fatG: 0,
          entries: [],
          weeklyCalories: [],
          macroTargets: MacroTargets.daily,
        );
    _state = NutritionState(
      targetCalories: s.targetCalories,
      consumedCalories: s.consumedCalories + entry.calories,
      proteinG: s.proteinG + entry.proteinG,
      carbsG: s.carbsG + entry.carbsG,
      fatG: s.fatG + entry.fatG,
      entries: [...s.entries, entry],
      weeklyCalories: s.weeklyCalories,
      macroTargets: s.macroTargets,
    );
    notifyListeners();
  }
}
