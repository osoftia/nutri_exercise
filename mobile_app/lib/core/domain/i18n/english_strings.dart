import 'app_language.dart';
import 'app_strings.dart';

/// English dictionary (the default language).
class EnglishStrings extends AppStrings {
  /// Creates the English dictionary.
  const EnglishStrings();

  @override
  String get appTitle => 'NutriExercise';

  @override
  String get navRoutines => 'Routines';
  @override
  String get navNutrition => 'Nutrition';
  @override
  String get navSchedule => 'Schedule';
  @override
  String get navProfile => 'Profile';

  @override
  String get routinesTitle => 'Routines';
  @override
  String get nutritionTitle => 'Nutrition';
  @override
  String get profileTitle => 'Profile';

  @override
  String get save => 'Save';
  @override
  String get cancel => 'Cancel';
  @override
  String get add => 'Add';
  @override
  String get delete => 'Delete';
  @override
  String get close => 'Close';
  @override
  String get history => 'History';
  @override
  String get weeklyStats => 'Weekly Stats';
  @override
  String get dailyRoutineSummary => 'Daily Routine Summary';
  @override
  String get dailyNutritionSummary => 'Daily Nutrition Summary';

  @override
  String get quickAddTitle => 'Quick Add';
  @override
  String get calorieLabel => 'Calories';
  @override
  String get proteinLabel => 'Protein';
  @override
  String get carbsLabel => 'Carbs';
  @override
  String get fatLabel => 'Fat';
  @override
  String get portionLabel => 'Portion (g)';

  @override
  String addFoodTitle(String foodName) => 'Add $foodName';

  @override
  String get quickAddOatmealBerries => 'Oatmeal & Berries';
  @override
  String get quickAddGrilledChickenBowl => 'Grilled Chicken Bowl';
  @override
  String get quickAddSalmonQuinoa => 'Salmon & Quinoa';
  @override
  String get quickAddGreekYogurtAlmonds => 'Greek Yogurt & Almonds';
  @override
  String get quickAddProteinShake => 'Protein Shake';

  @override
  String get languageSectionTitle => 'Language';
  @override
  String get languageSectionSubtitle => 'Choose your app language';

  @override
  String languageName(AppLanguage language) => switch (language) {
        AppLanguage.english => 'English',
        AppLanguage.spanish => 'Español',
      };
}
