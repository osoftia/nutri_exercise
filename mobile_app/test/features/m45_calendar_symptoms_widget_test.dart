import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/mocks/mock_daily_entry_repository.dart';
import 'package:nutri_mobile_app/core/mocks/mock_schedule_repository.dart';
import 'package:nutri_mobile_app/core/mocks/mock_symptom_repository.dart';
import 'package:nutri_mobile_app/core/models/symptom_log.dart';
import 'package:nutri_mobile_app/core/state/schedule_controller.dart';
import 'package:nutri_mobile_app/core/state/symptom_controller.dart';
import 'package:nutri_mobile_app/core/theme/app_theme.dart';
import 'package:nutri_mobile_app/ui/atoms/circular_icon_button.dart';
import 'package:nutri_mobile_app/ui/organisms/calendar_history_dialog.dart';
import 'package:nutri_mobile_app/ui/pages/schedule_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<SymptomController> pumpSchedule(WidgetTester tester) async {
    tester.view.physicalSize = const Size(900, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final scheduleController = ScheduleController(
      repository: MockScheduleRepository(),
      initialMonth: DateTime(2026, 8),
    );
    final symptomController = SymptomController(
      repository: MockSymptomRepository(),
      date: DateTime(2026, 8, 5),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: SchedulePage(
          controller: scheduleController,
          symptomController: symptomController,
        ),
      ),
    );
    await tester.pumpAndSettle();
    return symptomController;
  }

  group('M45 calendar & symptom refactor', () {
    testWidgets('mounts the symptom tracker on the calendar tab', (
      tester,
    ) async {
      await pumpSchedule(tester);

      expect(find.byKey(const Key('symptom_tracker')), findsOneWidget);
      for (final type in SymptomType.values) {
        expect(find.byKey(Key('symptom_${type.name}')), findsOneWidget);
      }
    });

    testWidgets('month navigation uses the circular icon pattern', (
      tester,
    ) async {
      await pumpSchedule(tester);

      expect(
        find.byKey(const Key('prev_month_button')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('next_month_button')),
        findsOneWidget,
      );
      expect(
        tester.widget(find.byKey(const Key('prev_month_button'))),
        isA<CircularIconButton>(),
      );

      await tester.tap(find.byKey(const Key('next_month_button')));
      await tester.pumpAndSettle();
      expect(find.text('September 2026'), findsOneWidget);
    });

    testWidgets('logging a symptom from the calendar persists it', (
      tester,
    ) async {
      final controller = await pumpSchedule(tester);

      await tester.tap(find.byKey(const Key('symptom_stress')));
      await tester.pumpAndSettle();

      expect(controller.levelOf(SymptomType.stress), 1);
    });

    testWidgets('calendar sections use generous, breathable spacing', (
      tester,
    ) async {
      await pumpSchedule(tester);

      final listView = tester.widget<ListView>(find.byType(ListView).first);
      final padding = listView.padding! as EdgeInsets;
      expect(padding.bottom, AppSpacing.pageBottom);
      expect(AppSpacing.section, greaterThanOrEqualTo(32));
      expect(AppSpacing.pageBottom, greaterThanOrEqualTo(40));
    });
  });

  group('M45 calendar history refactor', () {
    testWidgets('history month navigation uses the circular icon pattern', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(900, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: CalendarHistoryDialog(
              repository: MockDailyEntryRepository(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        tester.widget(find.byKey(const Key('history_prev_month'))),
        isA<CircularIconButton>(),
      );
      expect(
        tester.widget(find.byKey(const Key('history_next_month'))),
        isA<CircularIconButton>(),
      );
    });
  });
}
