import 'app_language.dart';
import 'english_strings.dart';
import 'spanish_strings.dart';

/// The app's typed translation dictionary contract.
///
/// Every user-facing string is a getter, so a new language is a compile-checked
/// implementation rather than a bag of string keys: forgetting a translation
/// fails the build, and business logic never references a language directly.
abstract class AppStrings {
  /// Creates a dictionary.
  const AppStrings();

  /// The dictionary for [language].
  static AppStrings of(AppLanguage language) => switch (language) {
        AppLanguage.english => const EnglishStrings(),
        AppLanguage.spanish => const SpanishStrings(),
      };

  // App shell / navigation.
  String get appTitle;
  String get navRoutines;
  String get navNutrition;
  String get navSchedule;
  String get navProfile;

  // Screen headers.
  String get routinesTitle;
  String get nutritionTitle;
  String get profileTitle;

  // Common actions / dialogs.
  String get save;
  String get cancel;
  String get add;
  String get delete;
  String get close;
  String get history;
  String get weeklyStats;
  String get dailyRoutineSummary;
  String get dailyNutritionSummary;

  // Nutrition dashboard.
  String get quickAddTitle;
  String get calorieLabel;
  String get proteinLabel;
  String get carbsLabel;
  String get fatLabel;
  String get portionLabel;

  /// Title of the gram-confirmation dialog for [foodName].
  String addFoodTitle(String foodName);

  // Quick-add presets.
  String get quickAddOatmealBerries;
  String get quickAddGrilledChickenBowl;
  String get quickAddSalmonQuinoa;
  String get quickAddGreekYogurtAlmonds;
  String get quickAddProteinShake;

  // Language settings.
  String get languageSectionTitle;
  String get languageSectionSubtitle;

  /// Localized display name of a supported [language].
  String languageName(AppLanguage language);
}
