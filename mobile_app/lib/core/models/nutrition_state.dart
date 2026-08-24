import 'food_entry.dart';

/// Immutable snapshot of a day's nutrition, bundled together so a repository
/// can persist/restore it in one shot.
class NutritionState {
  const NutritionState({
    required this.targetCalories,
    required this.consumedCalories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.entries,
    required this.weeklyCalories,
    required this.macroTargets,
  });

  final int targetCalories;
  final int consumedCalories;
  final int proteinG;
  final int carbsG;
  final int fatG;
  final List<FoodEntry> entries;

  /// Seven values Mon–Sun.
  final List<int> weeklyCalories;
  final MacroTargets macroTargets;
}
