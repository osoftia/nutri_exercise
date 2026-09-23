import '../../models/symptom_log.dart';
import '../../models/user_profile.dart';
import '../popups/exercise_completion.dart';
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
  String get addFoodsTitle => 'Add foods';
  @override
  String get logAMealShortTitle => 'Log a meal';
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

  // --- Routines tab -----------------------------------------------------
  @override
  String get bodyProjectionLabel => 'Body Projection';
  @override
  String get workoutCompletedTitle => 'Workout completed';
  @override
  String get workoutCompletedSubtitle =>
      "Records today's workout and grows your avatar";

  // --- Schedule tab -----------------------------------------------------
  @override
  String get scheduleTitle => 'Schedule';
  @override
  String get noEventsScheduled => 'No events scheduled';

  static const List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  static const List<String> _weekdayNarrow = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];
  static const List<String> _weekdayShort = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
  ];

  @override
  String monthYear(DateTime date) =>
      '${_months[date.month - 1]} ${date.year}';

  @override
  String weekdayNarrow(int weekday) => _weekdayNarrow[weekday - 1];

  @override
  String weekdayShort(int weekday) => _weekdayShort[weekday - 1];

  @override
  String agendaTitle(DateTime date) =>
      '${_weekdayShort[date.weekday - 1]}, ${date.day} '
      '${_months[date.month - 1]}';

  @override
  String get previousMonthTooltip => 'Previous month';
  @override
  String get nextMonthTooltip => 'Next month';

  // --- Symptom tracker --------------------------------------------------
  @override
  String get symptomTrackerTitle => 'Daily symptoms';
  @override
  String get symptomTrackerSubtitle =>
      'Long-press an icon to see what it tracks';
  @override
  String get symptomNoneLogged => 'No symptoms logged today.';

  @override
  String symptomLabel(SymptomType type) => switch (type) {
        SymptomType.pain => 'Pain',
        SymptomType.discomfort => 'Body discomfort',
        SymptomType.energy => 'Energy',
        SymptomType.stress => 'Stress',
      };

  @override
  String symptomTooltip(SymptomType type) =>
      '${symptomLabel(type)} — tap to cycle severity';

  @override
  String symptomLevel(int level) => switch (level) {
        0 => 'None',
        1 => 'Mild',
        2 => 'Moderate',
        _ => 'Severe',
      };

  // --- Nutrition dashboard ---------------------------------------------
  @override
  String get reactiveNotificationsTitle => 'Reactive meal notifications';
  @override
  String get reactiveNotificationsSubtitle =>
      'Notify right after logging a meal';
  @override
  String get exerciseNotButton => 'EXERCISE NOT';
  @override
  String get testNotificationsButton => 'Test Notifications';
  @override
  String get weeklyCaloriesTitle => 'Weekly Calories';
  @override
  String get logAMealTitle => 'Log a meal';
  @override
  String get nameFieldLabel => 'Name';
  @override
  String get nameFieldHint => 'e.g. Banana';
  @override
  String get caloriesFieldLabel => 'Calories';
  @override
  String get caloriesFieldHint => 'e.g. 120';

  @override
  String caloriesOfTarget(int consumed, int target) =>
      '$consumed of $target kcal';

  @override
  String macroOfTarget(int value, int target) => '$value / ${target}g';

  // --- Workout completion sheet ----------------------------------------
  @override
  String get workoutCompleteTitle => 'Workout Complete';
  @override
  String get nothingLoggedYet => 'Nothing logged yet';
  @override
  String get completionEmptyBody =>
      'No exercises were completed for this check-in.';
  @override
  String get doneButton => 'Done';

  @override
  String setsAndReps(int sets, int reps) => '$sets sets · $reps reps';

  @override
  String setsRepsLoad(int completed, int planned, int reps, String load) =>
      '$completed/$planned × $reps · ${load}kg';

  @override
  String get caloriesBurnedLabel => 'Calories burned';

  @override
  String recoveryLabel(String region, RecoveryLevel level) {
    final suffix = switch (level) {
      RecoveryLevel.recovered => 'RECOVERED',
      RecoveryLevel.recovering => 'RECOVERING',
      RecoveryLevel.fatigued => 'FATIGUED',
    };
    return '${region.toUpperCase()} · $suffix';
  }

  // --- Food / stomach sheet --------------------------------------------
  @override
  String get stomachTitle => 'Stomach';
  @override
  String get foodLoggedToday => 'Food logged today';
  @override
  String get noFoodLoggedToday => 'No food logged today.';

  @override
  String macroSummary(int protein, int carbs, int fat) =>
      'P ${protein}g · C ${carbs}g · F ${fat}g';

  @override
  String get totalLabel => 'Total';

  @override
  String itemCount(int count) => '$count ${count == 1 ? 'item' : 'items'}';

  @override
  String removeItemTooltip(String name) => 'Remove $name';
  @override
  String get deletionOnlyLabel => 'Deletion only';

  @override
  String kcal(int calories) => '$calories kcal';

  @override
  String kcalAmount(num calories) => '${calories.toStringAsFixed(0)} kcal';

  // --- Exercise detail sheet -------------------------------------------
  @override
  String get noPlanForMuscle => 'No plan for this muscle yet';
  @override
  String get noExercisesPlanned => 'No exercises planned for this muscle group.';
  @override
  String get completedVsPlanned => 'Completed vs planned';
  @override
  String get aiSuggestionLabel => 'AI suggestion';

  @override
  String setsOfPlanned(int completed, int planned) =>
      '✓ $completed/$planned sets';

  @override
  String setsProgress(int completed, int planned) =>
      '$completed / $planned sets';

  @override
  String volumeOfPlanned(String completed, String planned) =>
      '$completed / $planned kg';

  // --- Routine summary sheet -------------------------------------------
  @override
  String get routineSummaryCaption => 'Planned vs completed sets';
  @override
  String get noRoutinePlanned => 'No routine planned for today.';
  @override
  String get totalSetsLabel => 'Total sets';

  @override
  String completedOfPlanned(int completed, int planned) =>
      '$completed / $planned';

  @override
  String regionLabel(BodyRegion region) => switch (region) {
        BodyRegion.chest => 'CHEST',
        BodyRegion.armLeft => 'ARM L',
        BodyRegion.armRight => 'ARM R',
        BodyRegion.legLeft => 'LEG L',
        BodyRegion.legRight => 'LEG R',
        BodyRegion.core => 'CORE',
        BodyRegion.head => 'HEAD',
        BodyRegion.neck => 'NECK',
      };

  // --- Weekly stats sheet ----------------------------------------------
  @override
  String get weeklyStatsCaption => 'Calories consumed vs burned (7 days)';
  @override
  String get weeklyMacrosTitle => 'Weekly macros';
  @override
  String get consumedLabel => 'Consumed';
  @override
  String get burnedLabel => 'Burned';
  @override
  String get balanceLabel => 'Balance';

  @override
  String signedKcal(int balance) {
    final sign = balance >= 0 ? '+' : '';
    return '$sign$balance kcal';
  }

  // --- Settings / notifications ----------------------------------------
  @override
  String get settingsTitle => 'Settings';
  @override
  String get notificationsSectionTitle => 'Notifications';
  @override
  String get savedRecordsTitle => 'Saved Records';
  @override
  String get noSavedRecords => 'No saved records.';
  @override
  String get notificationPreferencesTitle => 'Notification Preferences';
  @override
  String get exerciseAlertsLabel => 'Exercise alerts';
  @override
  String get foodAlertsLabel => 'Food alerts';
  @override
  String get dailyIntakeRemindersLabel => 'Daily intake reminders';
  @override
  String get deleteRecordTitle => 'Delete record';
  @override
  String get editFocusTitle => 'Edit focus';
  @override
  String get focusAreaLabel => 'Focus area';
  @override
  String get nightlyCheckInTestButton => 'Test nightly check-in';
  @override
  String get quickTestTitle => 'Quick test';
  @override
  String get userSettingsTitle => 'User Settings';
  @override
  String get systemSettingsTitle => 'System Settings';
  @override
  String get testsSectionTitle => 'Tests';
  @override
  String get mealTestButton => 'Test meal notification';
  @override
  String removeExerciseTooltip(String name) => 'Remove $name';

  // --- History dialog / editor -----------------------------------------
  @override
  String get editEntryTitle => 'Edit entry';

  @override
  String editEntryTitleFor(String date) => 'Edit $date';

  @override
  String get deleteRecordButton => 'Delete Record';

  @override
  String deleteRecordConfirm(String weekday) => 'Delete "$weekday" routine?';

  @override
  String get exercisesFieldLabel => 'Exercises (comma separated)';
  @override
  String get historyTodayEmpty => 'No entries for this day';
  @override
  String get logAMealAction => 'Log a meal';

  // --- Daily log sheet -------------------------------------------------
  @override
  String get dailyCheckInTitle => 'Daily Check-in';
  @override
  String get dailyCheckInSubtitle => 'What did you eat and train today?';
  @override
  String get dailyLogHint => 'Type your summary…';
  @override
  String get analyzingLabel => 'Analyzing…';

  @override
  String savedSummary(String summary) => 'Saved — $summary';

  // --- AI chat ---------------------------------------------------------
  @override
  String get aiAssistantTitle => 'AI Assistant';
  @override
  String get aiChatEmptyPrompt => 'Ask me to build a workout routine.';
  @override
  String get aiChatInputHint => 'Ask for a workout routine…';
  @override
  String get aiServiceUnavailable => 'AI service unavailable right now.';
  @override
  String get sendLabel => 'Send';
  @override
  String get offlineAiTitle => 'Offline AI';
  @override
  String get offlineAiBody => 'To consult the AI, please connect to the internet.';
  @override
  String get gotItButton => 'Got it';

  // --- Profile form / validation ---------------------------------------
  @override
  String get ageFieldLabel => 'Age';
  @override
  String get weightFieldLabel => 'Weight';
  @override
  String get heightFieldLabel => 'Height';
  @override
  String get fitnessGoalLabel => 'Fitness Goal';
  @override
  String get saveProfileButton => 'Save Profile';

  @override
  String requiredField(String label) => '$label is required';
  @override
  String get invalidNumberMessage => 'Enter a valid number';

  @override
  String minimumOneMessage(String label) => '$label must be at least 1';

  @override
  String fitnessGoal(FitnessGoal goal) => switch (goal) {
        FitnessGoal.muscleGain => 'Muscle Gain',
        FitnessGoal.fatLoss => 'Fat Loss',
        FitnessGoal.maintain => 'Maintain',
        FitnessGoal.endurance => 'Endurance',
      };

  // --- Main shell ------------------------------------------------------
  @override
  String get dailyLogFabLabel => 'Daily Log';
}
