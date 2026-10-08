import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/domain/i18n/app_language.dart';
import 'package:nutri_mobile_app/core/domain/i18n/app_strings.dart';
import 'package:nutri_mobile_app/core/domain/i18n/english_strings.dart';
import 'package:nutri_mobile_app/core/domain/i18n/localization_scope.dart';
import 'package:nutri_mobile_app/core/domain/i18n/spanish_strings.dart';
import 'package:nutri_mobile_app/core/models/user_profile.dart';
import 'package:nutri_mobile_app/core/models/symptom_log.dart';
import 'package:nutri_mobile_app/core/domain/popups/exercise_completion.dart';

/// A widget that renders **every** [AppStrings] getter, so a single pump proves
/// the whole dictionary is addressable and localizes without throwing.
class _AllStringsProbe extends StatelessWidget {
  const _AllStringsProbe();

  @override
  Widget build(BuildContext context) {
    final s = LocalizationScope.stringsOf(context);
    final now = DateTime(2026, 8, 5);
    final lines = <String>[
      s.appTitle,
      s.navRoutines,
      s.navNutrition,
      s.navSchedule,
      s.navProfile,
      s.routinesTitle,
      s.nutritionTitle,
      s.profileTitle,
      s.save,
      s.cancel,
      s.add,
      s.delete,
      s.close,
      s.history,
      s.weeklyStats,
      s.dailyRoutineSummary,
      s.dailyNutritionSummary,
      s.quickAddTitle,
      s.addFoodsTitle,
      s.logAMealShortTitle,
      s.calorieLabel,
      s.proteinLabel,
      s.carbsLabel,
      s.fatLabel,
      s.portionLabel,
      s.addFoodTitle('X'),
      s.quickAddOatmealBerries,
      s.quickAddGrilledChickenBowl,
      s.quickAddSalmonQuinoa,
      s.quickAddGreekYogurtAlmonds,
      s.quickAddProteinShake,
      s.languageSectionTitle,
      s.languageSectionSubtitle,
      s.languageName(AppLanguage.english),
      s.languageName(AppLanguage.spanish),
      s.bodyProjectionLabel,
      s.workoutCompletedTitle,
      s.workoutCompletedSubtitle,
      s.scheduleTitle,
      s.noEventsScheduled,
      s.monthYear(now),
      s.weekdayNarrow(1),
      s.weekdayShort(1),
      s.agendaTitle(now),
      s.previousMonthTooltip,
      s.nextMonthTooltip,
      s.symptomTrackerTitle,
      s.symptomTrackerSubtitle,
      s.symptomNoneLogged,
      s.symptomLabel(SymptomType.pain),
      s.symptomLabel(SymptomType.energy),
      s.symptomTooltip(SymptomType.pain),
      s.symptomLevel(2),
      s.reactiveNotificationsTitle,
      s.reactiveNotificationsSubtitle,
      s.exerciseNotButton,
      s.testNotificationsButton,
      s.weeklyCaloriesTitle,
      s.logAMealTitle,
      s.nameFieldLabel,
      s.nameFieldHint,
      s.caloriesFieldLabel,
      s.caloriesFieldHint,
      s.caloriesOfTarget(1000, 2000),
      s.macroOfTarget(50, 150),
      s.workoutCompleteTitle,
      s.nothingLoggedYet,
      s.completionEmptyBody,
      s.doneButton,
      s.setsAndReps(4, 40),
      s.setsRepsLoad(3, 4, 10, '60'),
      s.caloriesBurnedLabel,
      s.recoveryLabel('chest', RecoveryLevel.recovered),
      s.stomachTitle,
      s.foodLoggedToday,
      s.noFoodLoggedToday,
      s.macroSummary(10, 20, 5),
      s.totalLabel,
      s.itemCount(2),
      s.removeItemTooltip('X'),
      s.deletionOnlyLabel,
      s.kcal(200),
      s.kcalAmount(200),
      s.noPlanForMuscle,
      s.noExercisesPlanned,
      s.completedVsPlanned,
      s.aiSuggestionLabel,
      s.setsOfPlanned(4, 4),
      s.setsProgress(2, 4),
      s.volumeOfPlanned('100', '200'),
      s.routineSummaryCaption,
      s.noRoutinePlanned,
      s.totalSetsLabel,
      s.completedOfPlanned(3, 4),
      s.regionLabel(BodyRegion.chest),
      s.weeklyStatsCaption,
      s.consumedLabel,
      s.burnedLabel,
      s.balanceLabel,
      s.signedKcal(200),
      s.weeklyMacrosTitle,
      s.settingsTitle,
      s.notificationsSectionTitle,
      s.savedRecordsTitle,
      s.noSavedRecords,
      s.notificationPreferencesTitle,
      s.exerciseAlertsLabel,
      s.foodAlertsLabel,
      s.dailyIntakeRemindersLabel,
      s.requestTimeoutLabel(30),
      s.requestTimeoutDescription,
      s.recommendedClinicalNutritionTitle,
      s.addSuggestedMeal,
      s.designStyleTitle,
      s.appleMinimalistThemeLabel,
      s.technicalBlueprintThemeLabel,
      s.appleMinimalistThemeDescription,
      s.deleteRecordTitle,
      s.editFocusTitle,
      s.focusAreaLabel,
      s.nightlyCheckInTestButton,
      s.quickTestTitle,
      s.userSettingsTitle,
      s.systemSettingsTitle,
      s.testsSectionTitle,
      s.mealTestButton,
      s.removeExerciseTooltip('X'),
      s.editEntryTitle,
      s.editEntryTitleFor('2026-08-05'),
      s.deleteRecordButton,
      s.deleteRecordConfirm('Monday'),
      s.exercisesFieldLabel,
      s.historyTodayEmpty,
      s.logAMealAction,
      s.dailyCheckInTitle,
      s.dailyCheckInSubtitle,
      s.dailyLogHint,
      s.analyzingLabel,
      s.savedSummary('200 kcal'),
      s.aiAssistantTitle,
      s.aiChatEmptyPrompt,
      s.aiChatInputHint,
      s.aiServiceUnavailable,
      s.sendLabel,
      s.offlineAiTitle,
      s.offlineAiBody,
      s.gotItButton,
      s.ageFieldLabel,
      s.weightFieldLabel,
      s.heightFieldLabel,
      s.fitnessGoalLabel,
      s.saveProfileButton,
      s.requiredField('Name'),
      s.invalidNumberMessage,
      s.minimumOneMessage('Age'),
      s.fitnessGoal(FitnessGoal.fatLoss),
      s.dailyLogFabLabel,
    ];
    return SingleChildScrollView(
      child: Column(
        children: [for (final line in lines) Text(line)],
      ),
    );
  }
}

Widget _harness(AppLanguage language) => MaterialApp(
      home: LocalizationScope(
        language: language,
        child: const Scaffold(body: _AllStringsProbe()),
      ),
    );

/// The first (always-rendered) labels of the probe, used to prove the scope
/// reaches real widgets in both languages.
const _englishHead = ['NutriExercise', 'Routines', 'Nutrition'];
const _spanishHead = ['NutriExercise', 'Rutinas', 'Nutrición'];

void main() {
  group('i18n full coverage — dictionary contract', () {
    test('every key is non-empty in both languages', () {
      for (final language in AppLanguage.values) {
        final s = AppStrings.of(language);
        for (final value in _sampleKeys(s)) {
          expect(value.trim(), isNotEmpty,
              reason: '$language produced a blank');
        }
      }
    });

    test('English and Spanish differ on core labels', () {
      const en = EnglishStrings();
      const es = SpanishStrings();
      expect(en.navRoutines, isNot(es.navRoutines));
      expect(en.nutritionTitle, isNot(es.nutritionTitle));
      expect(en.stomachTitle, isNot(es.stomachTitle));
      expect(en.workoutCompleteTitle, isNot(es.workoutCompleteTitle));
      expect(en.dailyCheckInTitle, isNot(es.dailyCheckInTitle));
    });
  });

  group('i18n full coverage — rendered UI', () {
    testWidgets('the probe renders localized labels in English',
        (tester) async {
      await tester.pumpWidget(_harness(AppLanguage.english));
      for (final label in _englishHead) {
        expect(find.text(label), findsWidgets, reason: label);
      }
    });

    testWidgets('the probe renders localized labels in Spanish',
        (tester) async {
      await tester.pumpWidget(_harness(AppLanguage.spanish));
      for (final label in _spanishHead) {
        expect(find.text(label), findsWidgets, reason: label);
      }
      // Spanish content that is not English.
      expect(find.text('Rutinas'), findsWidgets);
    });
  });
}

/// Collects one representative value for every contract getter.
List<String> _sampleKeys(AppStrings s) {
  const level = RecoveryLevel.recovered;
  return [
    s.appTitle,
    s.navRoutines,
    s.navNutrition,
    s.navSchedule,
    s.navProfile,
    s.routinesTitle,
    s.nutritionTitle,
    s.profileTitle,
    s.save,
    s.cancel,
    s.add,
    s.delete,
    s.close,
    s.history,
    s.weeklyStats,
    s.dailyRoutineSummary,
    s.dailyNutritionSummary,
    s.quickAddTitle,
    s.addFoodsTitle,
    s.logAMealShortTitle,
    s.calorieLabel,
    s.proteinLabel,
    s.carbsLabel,
    s.fatLabel,
    s.portionLabel,
    s.addFoodTitle('X'),
    s.quickAddOatmealBerries,
    s.quickAddGrilledChickenBowl,
    s.quickAddSalmonQuinoa,
    s.quickAddGreekYogurtAlmonds,
    s.quickAddProteinShake,
    s.languageSectionTitle,
    s.languageSectionSubtitle,
    s.languageName(AppLanguage.english),
    s.languageName(AppLanguage.spanish),
    s.bodyProjectionLabel,
    s.workoutCompletedTitle,
    s.workoutCompletedSubtitle,
    s.scheduleTitle,
    s.noEventsScheduled,
    s.monthYear(DateTime(2026, 8, 5)),
    s.weekdayNarrow(1),
    s.weekdayShort(1),
    s.agendaTitle(DateTime(2026, 8, 5)),
    s.previousMonthTooltip,
    s.nextMonthTooltip,
    s.symptomTrackerTitle,
    s.symptomTrackerSubtitle,
    s.symptomNoneLogged,
    s.symptomLabel(SymptomType.pain),
    s.symptomLabel(SymptomType.energy),
    s.symptomTooltip(SymptomType.pain),
    s.symptomLevel(2),
    s.reactiveNotificationsTitle,
    s.reactiveNotificationsSubtitle,
    s.exerciseNotButton,
    s.testNotificationsButton,
    s.weeklyCaloriesTitle,
    s.logAMealTitle,
    s.nameFieldLabel,
    s.nameFieldHint,
    s.caloriesFieldLabel,
    s.caloriesFieldHint,
    s.caloriesOfTarget(1000, 2000),
    s.macroOfTarget(50, 150),
    s.workoutCompleteTitle,
    s.nothingLoggedYet,
    s.completionEmptyBody,
    s.doneButton,
    s.setsAndReps(4, 40),
    s.setsRepsLoad(3, 4, 10, '60'),
    s.caloriesBurnedLabel,
    s.recoveryLabel('chest', level),
    s.stomachTitle,
    s.foodLoggedToday,
    s.noFoodLoggedToday,
    s.macroSummary(10, 20, 5),
    s.totalLabel,
    s.itemCount(2),
    s.removeItemTooltip('X'),
    s.deletionOnlyLabel,
    s.kcal(200),
    s.kcalAmount(200),
    s.noPlanForMuscle,
    s.noExercisesPlanned,
    s.completedVsPlanned,
    s.aiSuggestionLabel,
    s.setsOfPlanned(4, 4),
    s.setsProgress(2, 4),
    s.volumeOfPlanned('100', '200'),
    s.routineSummaryCaption,
    s.noRoutinePlanned,
    s.totalSetsLabel,
    s.completedOfPlanned(3, 4),
    s.regionLabel(BodyRegion.chest),
    s.weeklyStatsCaption,
    s.consumedLabel,
    s.burnedLabel,
    s.balanceLabel,
    s.signedKcal(200),
    s.weeklyMacrosTitle,
    s.settingsTitle,
    s.notificationsSectionTitle,
    s.savedRecordsTitle,
    s.noSavedRecords,
    s.notificationPreferencesTitle,
    s.exerciseAlertsLabel,
    s.foodAlertsLabel,
    s.dailyIntakeRemindersLabel,
    s.requestTimeoutLabel(30),
    s.requestTimeoutDescription,
    s.recommendedClinicalNutritionTitle,
    s.addSuggestedMeal,
    s.designStyleTitle,
    s.appleMinimalistThemeLabel,
    s.technicalBlueprintThemeLabel,
    s.appleMinimalistThemeDescription,
    s.deleteRecordTitle,
    s.editFocusTitle,
    s.focusAreaLabel,
    s.nightlyCheckInTestButton,
    s.quickTestTitle,
    s.userSettingsTitle,
    s.systemSettingsTitle,
    s.testsSectionTitle,
    s.mealTestButton,
    s.removeExerciseTooltip('X'),
    s.editEntryTitle,
    s.editEntryTitleFor('2026-08-05'),
    s.deleteRecordButton,
    s.deleteRecordConfirm('Monday'),
    s.exercisesFieldLabel,
    s.historyTodayEmpty,
    s.logAMealAction,
    s.dailyCheckInTitle,
    s.dailyCheckInSubtitle,
    s.dailyLogHint,
    s.analyzingLabel,
    s.savedSummary('200 kcal'),
    s.aiAssistantTitle,
    s.aiChatEmptyPrompt,
    s.aiChatInputHint,
    s.aiServiceUnavailable,
    s.sendLabel,
    s.offlineAiTitle,
    s.offlineAiBody,
    s.gotItButton,
    s.ageFieldLabel,
    s.weightFieldLabel,
    s.heightFieldLabel,
    s.fitnessGoalLabel,
    s.saveProfileButton,
    s.requiredField('Name'),
    s.invalidNumberMessage,
    s.minimumOneMessage('Age'),
    s.fitnessGoal(FitnessGoal.fatLoss),
    s.dailyLogFabLabel,
  ];
}
