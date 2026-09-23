import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/domain/i18n/app_language.dart';
import 'package:nutri_mobile_app/core/domain/i18n/localization_scope.dart';
import 'package:nutri_mobile_app/core/mocks/mock_daily_entry_repository.dart';
import 'package:nutri_mobile_app/core/mocks/mock_nutrition_repository.dart';
import 'package:nutri_mobile_app/core/state/nutrition_controller.dart';
import 'package:nutri_mobile_app/core/theme/app_theme.dart';
import 'package:nutri_mobile_app/ui/pages/nutrition_page.dart';

void main() {
  Future<void> pumpNutrition(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 6000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: LocalizationScope(
          language: AppLanguage.spanish,
          child: NutritionPage(
            controller: NutritionController(
              repository: MockNutritionRepository(),
            ),
            dailyEntryRepository: MockDailyEntryRepository(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('M47 nutrition input & quick-add redesign', () {
    testWidgets('quick-add and meal titles use the new Spanish labels', (
      tester,
    ) async {
      await pumpNutrition(tester);

      expect(find.text('Añadir alimentos'), findsOneWidget);
      expect(find.text('Registrar una comida'), findsOneWidget);
      expect(find.text('Añadir rápido'), findsNothing);
    });

    testWidgets('food input fields use smooth rounded borders', (tester) async {
      await pumpNutrition(tester);

      final field = tester.widget<TextField>(
        find.byKey(const Key('food_name_field')),
      );
      final border = field.decoration!.enabledBorder! as OutlineInputBorder;
      expect(border.borderRadius, BorderRadius.circular(AppRadius.pill));
      expect(field.decoration!.filled, isTrue);
    });
  });
}
