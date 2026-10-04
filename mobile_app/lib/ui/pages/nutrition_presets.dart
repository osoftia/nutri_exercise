import '../../core/domain/i18n/app_strings.dart';
import '../../core/models/food_entry.dart';

/// The canonical Nutrition-tab quick-add presets (per 100 g) and their
/// localized labels.
///
/// Extracted from `nutrition_page.dart` (M48 decomposition) so the page stays
/// focused on layout and logging.
class NutritionPresets {
  NutritionPresets._();

  /// The preset quick-add foods, authored per 100 g.
  static const List<FoodEntry> quickAdds = [
    FoodEntry(
      name: 'Oatmeal & Berries',
      calories: 420,
      proteinG: 10,
      carbsG: 60,
      fatG: 12,
      saturatedFatG: 1,
      sugarsG: 7,
      fiberG: 8,
      glycemicIndex: 55,
      purinesMg: 15,
      sodiumMg: 10,
    ),
    FoodEntry(
      name: 'Grilled Chicken Bowl',
      calories: 650,
      proteinG: 45,
      carbsG: 55,
      fatG: 18,
      saturatedFatG: 3,
      sugarsG: 4,
      fiberG: 5,
      glycemicIndex: 50,
      purinesMg: 180,
      sodiumMg: 620,
    ),
    FoodEntry(
      name: 'Salmon & Quinoa',
      calories: 580,
      proteinG: 35,
      carbsG: 45,
      fatG: 22,
      saturatedFatG: 3.5,
      sugarsG: 2,
      fiberG: 5,
      glycemicIndex: 45,
      purinesMg: 170,
      sodiumMg: 420,
    ),
    FoodEntry(
      name: 'Greek Yogurt & Almonds',
      calories: 240,
      proteinG: 18,
      carbsG: 18,
      fatG: 10,
      saturatedFatG: 3,
      sugarsG: 8,
      fiberG: 4,
      glycemicIndex: 35,
      purinesMg: 45,
      sodiumMg: 80,
    ),
    FoodEntry(
      name: 'Protein Shake',
      calories: 150,
      proteinG: 30,
      carbsG: 6,
      fatG: 1,
      saturatedFatG: 0.5,
      sugarsG: 2,
      fiberG: 0,
      glycemicIndex: 30,
      purinesMg: 20,
      sodiumMg: 180,
    ),
    FoodEntry(
      name: 'Red Meat Steak',
      calories: 250,
      proteinG: 26,
      carbsG: 0,
      fatG: 15,
      saturatedFatG: 8,
      sugarsG: 0,
      fiberG: 0,
      glycemicIndex: 0,
      purinesMg: 170,
      sodiumMg: 70,
    ),
    FoodEntry(
      name: 'Sweet Soda',
      calories: 100,
      carbsG: 25,
      sugarsG: 24,
      fiberG: 0,
      glycemicIndex: 78,
      saturatedFatG: 0,
      purinesMg: 0,
      sodiumMg: 30,
    ),
    FoodEntry(
      name: 'Organ Meat',
      calories: 180,
      proteinG: 26,
      fatG: 5,
      saturatedFatG: 2,
      sugarsG: 0,
      fiberG: 0,
      purinesMg: 220,
      sodiumMg: 80,
    ),
    FoodEntry(
      name: 'Instant Soup',
      calories: 90,
      carbsG: 15,
      saturatedFatG: 1,
      sugarsG: 2,
      fiberG: 1,
      purinesMg: 20,
      sodiumMg: 900,
    ),
    FoodEntry(
      name: 'Fresh Fruit Bowl',
      calories: 80,
      carbsG: 18,
      saturatedFatG: 0,
      sugarsG: 8,
      fiberG: 6,
      glycemicIndex: 50,
      purinesMg: 20,
      sodiumMg: 5,
    ),
  ];

  /// Localized label for [entry], keyed by its canonical name.
  static String label(AppStrings strings, FoodEntry entry) =>
      switch (entry.name) {
        'Oatmeal & Berries' => strings.quickAddOatmealBerries,
        'Grilled Chicken Bowl' => strings.quickAddGrilledChickenBowl,
        'Salmon & Quinoa' => strings.quickAddSalmonQuinoa,
        'Greek Yogurt & Almonds' => strings.quickAddGreekYogurtAlmonds,
        'Protein Shake' => strings.quickAddProteinShake,
        _ => entry.name,
      };
}
