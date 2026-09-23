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
    ),
    FoodEntry(
      name: 'Grilled Chicken Bowl',
      calories: 650,
      proteinG: 45,
      carbsG: 55,
      fatG: 18,
    ),
    FoodEntry(
      name: 'Salmon & Quinoa',
      calories: 580,
      proteinG: 35,
      carbsG: 45,
      fatG: 22,
    ),
    FoodEntry(
      name: 'Greek Yogurt & Almonds',
      calories: 240,
      proteinG: 18,
      carbsG: 18,
      fatG: 10,
    ),
    FoodEntry(
      name: 'Protein Shake',
      calories: 150,
      proteinG: 30,
      carbsG: 6,
      fatG: 1,
    ),
  ];

  /// Localized label for [entry], keyed by its canonical name.
  static String label(AppStrings strings, FoodEntry entry) => switch (entry.name) {
    'Oatmeal & Berries' => strings.quickAddOatmealBerries,
    'Grilled Chicken Bowl' => strings.quickAddGrilledChickenBowl,
    'Salmon & Quinoa' => strings.quickAddSalmonQuinoa,
    'Greek Yogurt & Almonds' => strings.quickAddGreekYogurtAlmonds,
    'Protein Shake' => strings.quickAddProteinShake,
    _ => entry.name,
  };
}
