import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/domain/i18n/app_language.dart';
import 'package:nutri_mobile_app/core/domain/i18n/app_strings.dart';
import 'package:nutri_mobile_app/core/domain/i18n/english_strings.dart';
import 'package:nutri_mobile_app/core/domain/i18n/localization_scope.dart';
import 'package:nutri_mobile_app/core/domain/i18n/spanish_strings.dart';

void main() {
  group('AppStrings (i18n Task 3)', () {
    test('resolves a concrete dictionary per language', () {
      expect(AppStrings.of(AppLanguage.english), isA<EnglishStrings>());
      expect(AppStrings.of(AppLanguage.spanish), isA<SpanishStrings>());
    });

    test('localizes navigation labels', () {
      const en = EnglishStrings();
      const es = SpanishStrings();
      expect(en.navRoutines, 'Routines');
      expect(es.navRoutines, 'Rutinas');
      expect(es.navNutrition, 'Nutrición');
      expect(es.navSchedule, 'Agenda');
      expect(es.navProfile, 'Perfil');
    });

    test('localizes screen headers and quick-add labels', () {
      const en = EnglishStrings();
      const es = SpanishStrings();
      expect(en.nutritionTitle, 'Nutrition');
      expect(es.nutritionTitle, 'Nutrición');
      expect(en.quickAddTitle, 'Quick Add');
      expect(es.quickAddTitle, 'Añadir rápido');
      expect(en.quickAddOatmealBerries, 'Oatmeal & Berries');
      expect(es.quickAddOatmealBerries, 'Avena con frutos rojos');
      expect(es.quickAddProteinShake, 'Batido de proteínas');
    });

    test('localizes dialogs and language settings', () {
      const en = EnglishStrings();
      const es = SpanishStrings();
      expect(en.addFoodTitle('Banana'), 'Add Banana');
      expect(es.addFoodTitle('Banana'), 'Añadir Banana');
      expect(es.cancel, 'Cancelar');
      expect(es.add, 'Añadir');
      expect(es.languageSectionTitle, 'Idioma');
      expect(en.languageName(AppLanguage.spanish), 'Español');
      expect(es.languageName(AppLanguage.english), 'Inglés');
    });

    test('every dictionary implements the full contract', () {
      for (final strings in const [EnglishStrings(), SpanishStrings()]) {
        for (final value in [
          strings.appTitle,
          strings.navRoutines,
          strings.navNutrition,
          strings.navSchedule,
          strings.navProfile,
          strings.routinesTitle,
          strings.nutritionTitle,
          strings.profileTitle,
          strings.save,
          strings.cancel,
          strings.add,
          strings.delete,
          strings.close,
          strings.history,
          strings.weeklyStats,
          strings.dailyRoutineSummary,
          strings.dailyNutritionSummary,
          strings.quickAddTitle,
          strings.calorieLabel,
          strings.proteinLabel,
          strings.carbsLabel,
          strings.fatLabel,
          strings.portionLabel,
          strings.addFoodTitle('X'),
          strings.quickAddOatmealBerries,
          strings.quickAddGrilledChickenBowl,
          strings.quickAddSalmonQuinoa,
          strings.quickAddGreekYogurtAlmonds,
          strings.quickAddProteinShake,
          strings.languageSectionTitle,
          strings.languageSectionSubtitle,
          strings.languageName(AppLanguage.english),
          strings.languageName(AppLanguage.spanish),
        ]) {
          expect(value.trim(), isNotEmpty);
        }
      }
    });
  });

  group('LocalizationScope (i18n Task 3)', () {
    testWidgets('falls back to English without a scope', (tester) async {
      late AppStrings strings;
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            strings = LocalizationScope.stringsOf(context);
            return const SizedBox.shrink();
          },
        ),
      );
      expect(strings, isA<EnglishStrings>());
    });

    testWidgets('provides the active dictionary and rebuilds on change', (
      tester,
    ) async {
      var language = AppLanguage.english;
      late StateSetter setState;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: StatefulBuilder(
            builder: (context, setter) {
              setState = setter;
              return LocalizationScope(
                language: language,
                child: Builder(
                  builder: (context) => Text(
                    LocalizationScope.stringsOf(context).navRoutines,
                  ),
                ),
              );
            },
          ),
        ),
      );
      expect(find.text('Routines'), findsOneWidget);

      setState(() => language = AppLanguage.spanish);
      await tester.pump();

      expect(find.text('Rutinas'), findsOneWidget);
      expect(find.text('Routines'), findsNothing);
    });
  });
}
