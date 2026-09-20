import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/domain/body_projection/body_segment.dart';
import 'package:nutri_mobile_app/core/mocks/mock_nutrition_repository.dart';
import 'package:nutri_mobile_app/core/models/food_entry.dart';
import 'package:nutri_mobile_app/core/models/nutrition_state.dart';
import 'package:nutri_mobile_app/core/state/nutrition_controller.dart';
import 'package:nutri_mobile_app/core/theme/app_theme.dart';
import 'package:nutri_mobile_app/ui/organisms/body_blueprint/body_blueprint_painter.dart';
import 'package:nutri_mobile_app/ui/pages/nutrition_page.dart';

void main() {
  Future<NutritionController> pumpNutrition(
    WidgetTester tester, {
    NutritionState? initialState,
  }) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final controller = NutritionController(
      repository: MockNutritionRepository(initialState: initialState),
    );
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.dark, home: NutritionPage(controller: controller)),
    );
    await tester.pumpAndSettle();
    return controller;
  }

  double abdomenScale(WidgetTester tester) {
    final customPaint = tester.widget<CustomPaint>(
      find.byKey(const Key('body_blueprint_paint')),
    );
    final painter = customPaint.painter! as BodyBlueprintPainter;
    return painter.viewModel.scaleFor(BodySegment.abdomen);
  }

  group('Nutrition dashboard', () {
    testWidgets('shows consumed vs target calories', (tester) async {
      await pumpNutrition(tester);

      final summary = find.byKey(const Key('calorie_summary'));
      expect(summary, findsOneWidget);
      expect(find.text('1000 of 2000 kcal'), findsOneWidget);
    });

    testWidgets('shows three macro rings and seven weekly bars', (tester) async {
      await pumpNutrition(tester);

      expect(find.text('Protein'), findsOneWidget);
      expect(find.text('Carbs'), findsOneWidget);
      expect(find.text('Fat'), findsOneWidget);
      expect(find.byKey(const Key('weekly_bar_chart')), findsOneWidget);
      for (var i = 0; i < 7; i++) {
        expect(find.byKey(Key('weekly_bar_$i')), findsOneWidget);
      }
    });

    testWidgets('quick add increments consumed calories immediately', (
      tester,
    ) async {
      final controller = await pumpNutrition(tester);

      await tester.tap(find.byKey(const Key('quick_add_Grilled Chicken Bowl')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('quick_add_confirm')));
      await tester.pumpAndSettle();

      expect(controller.consumedCalories, 1650);
      expect(find.text('1650 of 2000 kcal'), findsOneWidget);
    });

    testWidgets('blueprint figure is thin when calories are below target', (
      tester,
    ) async {
      await pumpNutrition(tester);

      expect(abdomenScale(tester), lessThan(1.0));
    });

    testWidgets('blueprint figure is wide when calories exceed target', (
      tester,
    ) async {
      await pumpNutrition(
        tester,
        initialState: const NutritionState(
          targetCalories: 2000,
          consumedCalories: 2200,
          proteinG: 30,
          carbsG: 80,
          fatG: 20,
          entries: [],
          weeklyCalories: [1800, 1500, 1200, 2000, 1750, 2400, 1450],
          macroTargets: MacroTargets.daily,
        ),
      );

      expect(abdomenScale(tester), greaterThan(1.0));
    });

    testWidgets('logging food scales the blueprint figure across the page', (
      tester,
    ) async {
      final controller = await pumpNutrition(tester);
      final before = abdomenScale(tester);

      await tester.tap(find.byKey(const Key('quick_add_Protein Shake')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('quick_add_confirm')));
      await tester.pumpAndSettle();

      expect(controller.consumedCalories, 1150);
      expect(abdomenScale(tester), greaterThan(before));
    });

    testWidgets('custom meal entry adds calories', (tester) async {
      final controller = await pumpNutrition(tester);

      await tester.enterText(
        find.byKey(const Key('food_name_field')),
        'Banana',
      );
      await tester.enterText(
        find.byKey(const Key('food_calories_field')),
        '120',
      );
      await tester.tap(find.byKey(const Key('food_add_button')));
      await tester.pumpAndSettle();

      expect(controller.consumedCalories, 1120);
    });

    testWidgets('custom meal entry with missing fields is ignored', (
      tester,
    ) async {
      final controller = await pumpNutrition(tester);

      await tester.tap(find.byKey(const Key('food_add_button')));
      await tester.pumpAndSettle();

      expect(controller.consumedCalories, 1000);
    });
  });
}
