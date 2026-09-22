import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/mocks/mock_daily_entry_repository.dart';
import 'package:nutri_mobile_app/core/mocks/mock_nutrition_repository.dart';
import 'package:nutri_mobile_app/core/models/daily_entry.dart';
import 'package:nutri_mobile_app/core/state/nutrition_controller.dart';
import 'package:nutri_mobile_app/core/theme/app_theme.dart';
import 'package:nutri_mobile_app/ui/pages/nutrition_page.dart';

void main() {
  testWidgets('logging food from Nutrition persists the daily totals', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 6000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final entries = MockDailyEntryRepository();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: NutritionPage(
          controller: NutritionController(repository: MockNutritionRepository()),
          dailyEntryRepository: entries,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final button = find.byKey(const Key('quick_add_Grilled Chicken Bowl'));
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();

    // Confirm the default 100 g portion.
    await tester.tap(find.byKey(const Key('quick_add_confirm')));
    await tester.pumpAndSettle();

    final today = DailyEntry.dateKey(DateTime.now());
    final saved = await entries.getByDate(today);
    expect(saved, isNotNull);
    expect(saved!.calories, 650);
    expect(saved.protein, 45);
    expect(saved.carbs, 55);
    expect(saved.fat, 18);
  });

  testWidgets('logging twice accumulates the daily totals', (tester) async {
    tester.view.physicalSize = const Size(1000, 6000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final entries = MockDailyEntryRepository();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: NutritionPage(
          controller: NutritionController(repository: MockNutritionRepository()),
          dailyEntryRepository: entries,
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (var i = 0; i < 2; i++) {
      final button = find.byKey(const Key('quick_add_Protein Shake'));
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      await tester.tap(button);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('quick_add_confirm')));
      await tester.pumpAndSettle();
    }

    final today = DailyEntry.dateKey(DateTime.now());
    final saved = await entries.getByDate(today);
    expect(saved!.calories, 300);
    expect(saved.protein, 60);
  });
}
