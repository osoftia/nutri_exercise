import '../../models/symptom_log.dart';
import '../../models/user_profile.dart';
import '../popups/exercise_completion.dart';
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
  String get addFoodsTitle;
  String get logAMealShortTitle;

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

  // --- Routines tab -----------------------------------------------------
  String get bodyProjectionLabel;
  String get workoutCompletedTitle;
  String get workoutCompletedSubtitle;

  // --- Schedule tab -----------------------------------------------------
  String get scheduleTitle;
  String get noEventsScheduled;

  /// Localized "Month YYYY" label (e.g. `August 2026` / `agosto de 2026`).
  String monthYear(DateTime date);

  /// Narrow Monday-first weekday header (`1 = Monday`).
  String weekdayNarrow(int weekday);

  /// Short Monday-first weekday label (`1 = Monday`, e.g. `Mon` / `lun`).
  String weekdayShort(int weekday);

  /// Localized agenda title (`"Mon, 5 May"` / `"lun, 5 de mayo"`).
  String agendaTitle(DateTime date);

  /// Long-press tooltip for the previous-month calendar control.
  String get previousMonthTooltip;

  /// Long-press tooltip for the next-month calendar control.
  String get nextMonthTooltip;

  // --- Symptom tracker --------------------------------------------------
  String get symptomTrackerTitle;
  String get symptomTrackerSubtitle;
  String get symptomNoneLogged;

  /// Localized name of a tracked [type] (e.g. `Pain`, `Energy`).
  String symptomLabel(SymptomType type);

  /// Long-press tooltip explaining what a [type] control tracks.
  String symptomTooltip(SymptomType type);

  /// Localized severity label for a `0..3` [level].
  String symptomLevel(int level);

  // --- Nutrition dashboard ---------------------------------------------
  String get reactiveNotificationsTitle;
  String get reactiveNotificationsSubtitle;
  String get exerciseNotButton;
  String get testNotificationsButton;
  String get weeklyCaloriesTitle;
  String get logAMealTitle;
  String get nameFieldLabel;
  String get nameFieldHint;
  String get caloriesFieldLabel;
  String get caloriesFieldHint;

  /// The `"<consumed> of <target> kcal"` summary.
  String caloriesOfTarget(int consumed, int target);

  /// A `"<value> / <target>g"` macro ring value label.
  String macroOfTarget(int value, int target);

  // --- Workout completion sheet ----------------------------------------
  String get workoutCompleteTitle;
  String get nothingLoggedYet;
  String get completionEmptyBody;
  String get doneButton;

  /// `"<sets> sets · <reps> reps"`.
  String setsAndReps(int sets, int reps);

  /// `"<completed>/<planned> × <reps> · <load>kg"`.
  String setsRepsLoad(int completed, int planned, int reps, String load);

  String get caloriesBurnedLabel;

  /// Localized recovery chip label for [level] (`REGION · LEVEL`).
  String recoveryLabel(String region, RecoveryLevel level);

  // --- Food / stomach sheet --------------------------------------------
  String get stomachTitle;
  String get foodLoggedToday;
  String get noFoodLoggedToday;

  /// `"P <protein>g · C <carbs>g · F <fat>g"`.
  String macroSummary(int protein, int carbs, int fat);

  String get totalLabel;

  /// `"<count> item"` / `"<count> items"` (singular-aware).
  String itemCount(int count);

  String removeItemTooltip(String name);
  String get deletionOnlyLabel;

  /// `"<calories> kcal"`.
  String kcal(int calories);

  /// `"<count> kcal"` from a numeric amount.
  String kcalAmount(num calories);

  // --- Exercise detail sheet -------------------------------------------
  String get noPlanForMuscle;
  String get noExercisesPlanned;
  String get completedVsPlanned;
  String get aiSuggestionLabel;

  /// `"✓ <completed>/<planned> sets"` for a fully completed exercise.
  String setsOfPlanned(int completed, int planned);

  /// `"<completed> / <planned> sets"` for a partially completed exercise.
  String setsProgress(int completed, int planned);

  /// `"<completed> / <planned> kg"` volume row.
  String volumeOfPlanned(String completed, String planned);

  // --- Routine summary sheet -------------------------------------------
  String get routineSummaryCaption;
  String get noRoutinePlanned;
  String get totalSetsLabel;

  /// `"<completed> / <planned>"`.
  String completedOfPlanned(int completed, int planned);

  /// Localized blueprint region label (e.g. `CHEST`, `ARM L`).
  String regionLabel(BodyRegion region);

  // --- Weekly stats sheet ----------------------------------------------
  String get weeklyStatsCaption;
  String get weeklyMacrosTitle;
  String get consumedLabel;
  String get burnedLabel;
  String get balanceLabel;

  /// A signed balance value (`+200` / `-200`).
  String signedKcal(int balance);

  // --- Settings / notifications ----------------------------------------
  String get settingsTitle;
  String get notificationsSectionTitle;
  String get savedRecordsTitle;
  String get noSavedRecords;
  String get notificationPreferencesTitle;
  String get exerciseAlertsLabel;
  String get foodAlertsLabel;
  String get dailyIntakeRemindersLabel;
  String get deleteRecordTitle;
  String get editFocusTitle;
  String get focusAreaLabel;
  String get nightlyCheckInTestButton;
  String get quickTestTitle;

  // --- Profile sections -------------------------------------------------
  String get userSettingsTitle;
  String get systemSettingsTitle;
  String get testsSectionTitle;
  String get mealTestButton;

  /// `"Remove <name>"` tooltip for an exercise's delete control.
  String removeExerciseTooltip(String name);

  // --- History dialog / editor -----------------------------------------
  String get editEntryTitle;

  /// `"Edit <date>"`.
  String editEntryTitleFor(String date);

  String get deleteRecordButton;

  /// `"Delete "<weekday>" routine?"`.
  String deleteRecordConfirm(String weekday);

  String get exercisesFieldLabel;
  String get historyTodayEmpty;
  String get logAMealAction;

  // --- Daily log sheet -------------------------------------------------
  String get dailyCheckInTitle;
  String get dailyCheckInSubtitle;
  String get dailyLogHint;
  String get analyzingLabel;

  /// `"Saved — <summary>"`.
  String savedSummary(String summary);

  // --- AI chat ---------------------------------------------------------
  String get aiAssistantTitle;
  String get aiChatEmptyPrompt;
  String get aiChatInputHint;
  String get aiServiceUnavailable;
  String get sendLabel;
  String get offlineAiTitle;
  String get offlineAiBody;
  String get gotItButton;

  // --- Profile form / validation ---------------------------------------
  String get ageFieldLabel;
  String get weightFieldLabel;
  String get heightFieldLabel;
  String get fitnessGoalLabel;
  String get saveProfileButton;
  String requiredField(String label);
  String get invalidNumberMessage;

  /// `"<label> must be at least 1"`.
  String minimumOneMessage(String label);

  /// Localized fitness goal label.
  String fitnessGoal(FitnessGoal goal);

  // --- Main shell ------------------------------------------------------
  String get dailyLogFabLabel;
}

/// Structural blueprint regions used by the routine summary labels.
///
/// Kept in the domain layer so dictionaries can localize them without the UI
/// leaking anatomy strings into hardcoded maps.
enum BodyRegion { chest, armLeft, armRight, legLeft, legRight, core, head, neck }
