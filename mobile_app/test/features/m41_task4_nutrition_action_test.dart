import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/domain/body_projection/body_segment.dart';
import 'package:nutri_mobile_app/core/mocks/mock_body_detail_repository.dart';
import 'package:nutri_mobile_app/core/mocks/mock_daily_entry_repository.dart';
import 'package:nutri_mobile_app/core/mocks/mock_nutrition_repository.dart';
import 'package:nutri_mobile_app/core/services/rule_based_muscle_gap_advisor.dart';
import 'package:nutri_mobile_app/core/state/body_detail_controller.dart';
import 'package:nutri_mobile_app/core/state/muscle_tamagotchi_state.dart';
import 'package:nutri_mobile_app/core/state/nutrition_controller.dart';
import 'package:nutri_mobile_app/core/theme/app_theme.dart';
import 'package:nutri_mobile_app/ui/pages/nutrition_page.dart';

Future<BodyDetailController> _pump(
  WidgetTester tester, {
  MuscleTamagotchiState? tamagotchi,
}) async {
  tester.view.physicalSize = const Size(1000, 6000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final detail = BodyDetailController(
    repository: MockBodyDetailRepository(),
    advisor: const RuleBasedMuscleGapAdvisor(),
    tamagotchi: tamagotchi,
  );
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark,
      home: NutritionPage(
        controller: NutritionController(repository: MockNutritionRepository()),
        dailyEntryRepository: MockDailyEntryRepository(),
        bodyDetailController: detail,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return detail;
}

void main() {
  testWidgets('the Nutrition tab shows the nutrition action button', (
    tester,
  ) async {
    await _pump(tester);
    expect(find.byKey(const Key('nutrition_action_button')), findsOneWidget);
  });

  testWidgets('tapping it opens the daily nutrition summary', (tester) async {
    await _pump(tester);

    await tester.tap(find.byKey(const Key('nutrition_action_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('body_food_sheet')), findsOneWidget);
  });

  testWidgets('adding a food from the summary bloats the stomach segment', (
    tester,
  ) async {
    final tamagotchi = MuscleTamagotchiState();
    final detail = await _pump(tester, tamagotchi: tamagotchi);
    final before = detail.buildViewModel().scaleFor(BodySegment.abdomen);

    await tester.tap(find.byKey(const Key('nutrition_action_button')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('body_add_food')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('body_add_food')));
    await tester.pumpAndSettle();

    expect(
      detail.buildViewModel().scaleFor(BodySegment.abdomen),
      greaterThan(before),
    );
  });
}
