/// A single logged food item with its caloric and macronutrient content.
class FoodEntry {
  const FoodEntry({
    required this.name,
    required this.calories,
    this.proteinG = 0,
    this.carbsG = 0,
    this.fatG = 0,
  });

  final String name;
  final int calories;
  final int proteinG;
  final int carbsG;
  final int fatG;
}

/// Daily macronutrient targets in grams.
class MacroTargets {
  const MacroTargets({
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  final int protein;
  final int carbs;
  final int fat;

  /// Default daily targets used when no custom targets are configured.
  static const MacroTargets daily = MacroTargets(
    protein: 150,
    carbs: 250,
    fat: 70,
  );
}
