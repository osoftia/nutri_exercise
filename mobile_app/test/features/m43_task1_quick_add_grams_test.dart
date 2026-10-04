import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/domain/body_projection/body_segment.dart';
import 'package:nutri_mobile_app/core/domain/nutrition/portion_scaler.dart';
import 'package:nutri_mobile_app/core/domain/body_projection/segment_status.dart';
import 'package:nutri_mobile_app/core/mocks/mock_body_detail_repository.dart';
import 'package:nutri_mobile_app/core/mocks/mock_nutrition_repository.dart';
import 'package:nutri_mobile_app/core/models/food_entry.dart';
import 'package:nutri_mobile_app/core/services/rule_based_muscle_gap_advisor.dart';
import 'package:nutri_mobile_app/core/state/body_detail_controller.dart';
import 'package:nutri_mobile_app/core/state/nutrition_controller.dart';
import 'package:nutri_mobile_app/core/theme/app_theme.dart';
import 'package:nutri_mobile_app/ui/pages/nutrition_page.dart';

const _oatmeal = FoodEntry(
  name: 'Oatmeal & Berries',
  calories: 420,
  proteinG: 10,
  carbsG: 60,
  fatG: 12,
  saturatedFatG: 1.2,
  sugarsG: 7,
  fiberG: 8,
  glycemicIndex: 55,
  purinesMg: 15,
  sodiumMg: 10,
);

Future<NutritionController> _pump(
  WidgetTester tester, {
  BodyDetailController? detail,
}) async {
  tester.view.physicalSize = const Size(1000, 6000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final controller = NutritionController(
    repository: MockNutritionRepository(),
  );
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark,
      home: NutritionPage(
        controller: controller,
        bodyDetailController: detail,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return controller;
}

Future<void> _openQuickAdd(WidgetTester tester, String label) async {
  await tester.ensureVisible(find.byKey(Key('quick_add_$label')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(Key('quick_add_$label')));
  await tester.pumpAndSettle();
}

void main() {
  group('M43 PortionScaler', () {
    test('defaults to the per-100g baseline', () {
      final scaled = PortionScaler.scaleFood(_oatmeal, 100);
      expect(scaled.calories, 420);
      expect(scaled.proteinG, 10);
      expect(scaled.carbsG, 60);
      expect(scaled.fatG, 12);
    });

    test('scales calories and macros proportionally', () {
      final scaled = PortionScaler.scaleFood(_oatmeal, 200);
      expect(scaled.calories, 840);
      expect(scaled.proteinG, 20);
      expect(scaled.carbsG, 120);
      expect(scaled.fatG, 24);
    });

    test('rounds scaled macros to the nearest gram', () {
      final scaled = PortionScaler.scaleFood(_oatmeal, 150);
      expect(scaled.calories, 630);
      expect(scaled.proteinG, 15);
      expect(scaled.carbsG, 90);
      expect(scaled.fatG, 18);
    });

    test('keeps the food name on the scaled entry', () {
      expect(PortionScaler.scaleFood(_oatmeal, 250).name, 'Oatmeal & Berries');
    });

    test('scales clinical nutrient amounts but preserves glycemic index', () {
      final scaled = PortionScaler.scaleFood(_oatmeal, 200);

      expect(scaled.saturatedFatG, closeTo(2.4, 0.001));
      expect(scaled.sugarsG, 14);
      expect(scaled.fiberG, 16);
      expect(scaled.glycemicIndex, 55);
      expect(scaled.purinesMg, 30);
      expect(scaled.sodiumMg, 20);
    });
  });

  group('M43 quick-add gram scaling flow', () {
    testWidgets('intercepts a quick-add and shows the gram dialog with 100g', (
      tester,
    ) async {
      await _pump(tester);
      await _openQuickAdd(tester, 'Oatmeal & Berries');

      expect(find.byKey(const Key('quick_add_grams_dialog')), findsOneWidget);
      final field = tester.widget<TextField>(
        find.byKey(const Key('quick_add_grams_field')),
      );
      expect(field.controller?.text, '100');
    });

    testWidgets('cancelling the dialog logs nothing', (tester) async {
      final controller = await _pump(tester);
      await _openQuickAdd(tester, 'Oatmeal & Berries');

      await tester.tap(find.byKey(const Key('quick_add_cancel')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('quick_add_grams_dialog')), findsNothing);
      expect(controller.consumedCalories, 1000);
    });

    testWidgets('confirming 100g logs the baseline portion', (tester) async {
      final controller = await _pump(tester);
      await _openQuickAdd(tester, 'Oatmeal & Berries');

      await tester.tap(find.byKey(const Key('quick_add_confirm')));
      await tester.pumpAndSettle();

      expect(controller.consumedCalories, 1420);
    });

    testWidgets('a custom gram value scales calories and macros',
        (tester) async {
      final controller = await _pump(tester);
      await _openQuickAdd(tester, 'Oatmeal & Berries');

      await tester.enterText(
        find.byKey(const Key('quick_add_grams_field')),
        '200',
      );
      await tester.tap(find.byKey(const Key('quick_add_confirm')));
      await tester.pumpAndSettle();

      expect(controller.consumedCalories, 1840);
      expect(controller.proteinG, 30 + 20);
      expect(controller.carbsG, 80 + 120);
      expect(controller.fatG, 20 + 24);
    });

    testWidgets('an invalid gram value is rejected', (tester) async {
      final controller = await _pump(tester);
      await _openQuickAdd(tester, 'Oatmeal & Berries');

      await tester.enterText(
        find.byKey(const Key('quick_add_grams_field')),
        'abc',
      );
      await tester.tap(find.byKey(const Key('quick_add_confirm')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('quick_add_grams_dialog')), findsOneWidget);
      expect(controller.consumedCalories, 1000);
    });

    testWidgets('scaled food reaches the blueprint abdomen status', (
      tester,
    ) async {
      final detail = BodyDetailController(
        repository: MockBodyDetailRepository(),
        advisor: const RuleBasedMuscleGapAdvisor(),
      );
      await _pump(tester, detail: detail);
      expect(
        detail.buildViewModel().statusFor(BodySegment.abdomen),
        SegmentStatus.noData,
      );

      await _openQuickAdd(tester, 'Oatmeal & Berries');
      await tester.tap(find.byKey(const Key('quick_add_confirm')));
      await tester.pumpAndSettle();

      expect(
        detail.buildViewModel().statusFor(BodySegment.abdomen),
        isNot(SegmentStatus.noData),
      );
      expect(detail.foodLog.entries.single.calories, 420);
      expect(detail.foodLog.entries.single.portion, contains('g'));
    });
  });
}
