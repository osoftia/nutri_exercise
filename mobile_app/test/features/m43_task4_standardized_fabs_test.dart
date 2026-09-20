import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/mocks/mock_body_detail_repository.dart';
import 'package:nutri_mobile_app/core/mocks/mock_daily_entry_repository.dart';
import 'package:nutri_mobile_app/core/mocks/mock_nutrition_repository.dart';
import 'package:nutri_mobile_app/core/mocks/mock_projection_repository.dart';
import 'package:nutri_mobile_app/core/services/rule_based_muscle_gap_advisor.dart';
import 'package:nutri_mobile_app/core/state/body_detail_controller.dart';
import 'package:nutri_mobile_app/core/state/nutrition_controller.dart';
import 'package:nutri_mobile_app/core/state/projection_controller.dart';
import 'package:nutri_mobile_app/core/theme/app_theme.dart';
import 'package:nutri_mobile_app/ui/atoms/blueprint_fab.dart';
import 'package:nutri_mobile_app/ui/molecules/blueprint_action_rail.dart';
import 'package:nutri_mobile_app/ui/pages/nutrition_page.dart';
import 'package:nutri_mobile_app/ui/pages/routines_page.dart';

Future<void> _pumpRoutines(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1000, 3000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: RoutinesPage(
          controller: ProjectionController(
            repository: MockProjectionRepository(),
          ),
          detailController: BodyDetailController(
            repository: MockBodyDetailRepository(),
            advisor: const RuleBasedMuscleGapAdvisor(),
          ),
          dailyEntryRepository: MockDailyEntryRepository(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpNutrition(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1000, 6000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark,
      home: NutritionPage(
        controller: NutritionController(repository: MockNutritionRepository()),
        dailyEntryRepository: MockDailyEntryRepository(),
        bodyDetailController: BodyDetailController(
          repository: MockBodyDetailRepository(),
          advisor: const RuleBasedMuscleGapAdvisor(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('M43 BlueprintActionRail', () {
    testWidgets('collapses to nothing when no action is available', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlueprintActionRail(
              showHistory: false,
              onSummary: null,
            ),
          ),
        ),
      );

      expect(find.byType(BlueprintActionRail), findsOneWidget);
      expect(find.byType(BlueprintFab), findsNothing);
    });
  });

  group('M43 Routines action rail', () {
    testWidgets('shows History and Daily Routine Summary beside the avatar', (
      tester,
    ) async {
      await _pumpRoutines(tester);

      expect(find.byKey(const Key('body_history_fab')), findsOneWidget);
      expect(find.byKey(const Key('routine_summary_button')), findsOneWidget);
      expect(find.byType(BlueprintActionRail), findsOneWidget);
    });

    testWidgets('the routine summary button opens the daily summary', (
      tester,
    ) async {
      await _pumpRoutines(tester);

      await tester.tap(find.byKey(const Key('routine_summary_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('routine_summary_sheet')), findsOneWidget);
      expect(find.byKey(const Key('routine_summary_total')), findsOneWidget);
    });
  });

  group('M43 Nutrition action rail', () {
    testWidgets('shows History and Daily Nutrition Summary beside the avatar', (
      tester,
    ) async {
      await _pumpNutrition(tester);

      expect(find.byKey(const Key('nutrition_history_fab')), findsOneWidget);
      expect(find.byKey(const Key('nutrition_action_button')), findsOneWidget);
    });

    testWidgets('the nutrition summary button opens the food sheet', (
      tester,
    ) async {
      await _pumpNutrition(tester);

      await tester.tap(find.byKey(const Key('nutrition_action_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('body_food_sheet')), findsOneWidget);
    });

    testWidgets('the nutrition history button opens the history dialog', (
      tester,
    ) async {
      await _pumpNutrition(tester);

      await tester.tap(find.byKey(const Key('nutrition_history_fab')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('calendar_history_dialog')), findsOneWidget);
    });
  });
}
