import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/mocks/mock_body_detail_repository.dart';
import 'package:nutri_mobile_app/core/mocks/mock_daily_entry_repository.dart';
import 'package:nutri_mobile_app/core/mocks/mock_projection_repository.dart';
import 'package:nutri_mobile_app/core/services/rule_based_muscle_gap_advisor.dart';
import 'package:nutri_mobile_app/core/state/body_detail_controller.dart';
import 'package:nutri_mobile_app/core/state/projection_controller.dart';
import 'package:nutri_mobile_app/core/theme/app_theme.dart';
import 'package:nutri_mobile_app/ui/pages/routines_page.dart';

Future<void> _pumpRoutines(
  WidgetTester tester, {
  bool withHistory = true,
}) async {
  tester.view.physicalSize = const Size(1000, 3000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: RoutinesPage(
          controller: ProjectionController(repository: MockProjectionRepository()),
          detailController: BodyDetailController(
            repository: MockBodyDetailRepository(),
            advisor: const RuleBasedMuscleGapAdvisor(),
          ),
          dailyEntryRepository:
              withHistory ? MockDailyEntryRepository() : null,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows a blueprint history FAB next to the diagram', (
    tester,
  ) async {
    await _pumpRoutines(tester);

    expect(find.byKey(const Key('body_history_fab')), findsOneWidget);
    expect(find.byKey(const Key('body_blueprint_paint')), findsOneWidget);
  });

  testWidgets('tapping the FAB opens the historical progress view', (
    tester,
  ) async {
    await _pumpRoutines(tester);

    await tester.tap(find.byKey(const Key('body_history_fab')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('calendar_history_dialog')), findsOneWidget);
  });

  testWidgets('hides the FAB when no history repository is provided', (
    tester,
  ) async {
    await _pumpRoutines(tester, withHistory: false);

    expect(find.byKey(const Key('body_history_fab')), findsNothing);
  });
}
