/// A single logged food item with its caloric and macronutrient content.
class FoodEntry {
  const FoodEntry({
    required this.name,
    required this.calories,
    this.proteinG = 0,
    this.carbsG = 0,
    this.fatG = 0,
    this.saturatedFatG,
    this.sugarsG,
    this.fiberG,
    this.glycemicIndex,
    this.purinesMg,
    this.sodiumMg,
  });

  final String name;
  final int calories;
  final int proteinG;
  final int carbsG;
  final int fatG;

  /// Optional clinical nutrition estimates per logged portion. `null` means
  /// the source did not provide the value and must not be interpreted as zero.
  final double? saturatedFatG;
  final double? sugarsG;
  final double? fiberG;
  final double? glycemicIndex;
  final double? purinesMg;
  final double? sodiumMg;
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
