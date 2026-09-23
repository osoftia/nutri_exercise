import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/mocks/mock_daily_entry_repository.dart';
import 'package:nutri_mobile_app/core/mocks/mock_schedule_repository.dart';
import 'package:nutri_mobile_app/core/mocks/mock_symptom_repository.dart';
import 'package:nutri_mobile_app/core/state/schedule_controller.dart';
import 'package:nutri_mobile_app/core/state/symptom_controller.dart';
import 'package:nutri_mobile_app/core/theme/app_theme.dart';
import 'package:nutri_mobile_app/ui/molecules/calendar_month_header.dart';
import 'package:nutri_mobile_app/ui/organisms/calendar_history_dialog.dart';
import 'package:nutri_mobile_app/ui/pages/schedule_page.dart';

void main() {
  Future<void> pumpSchedule(WidgetTester tester) async {
    tester.view.physicalSize = const Size(900, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: SchedulePage(
          controller: ScheduleController(
            repository: MockScheduleRepository(),
            initialMonth: DateTime(2026, 8),
          ),
          symptomController: SymptomController(
            repository: MockSymptomRepository(),
            date: DateTime(2026, 8, 5),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('M47 calendar header redesign', () {
    testWidgets('shows the clean centered month header', (tester) async {
      await pumpSchedule(tester);

      expect(find.byType(CalendarMonthHeader), findsOneWidget);
      expect(find.byKey(const Key('calendar_month_pill')), findsOneWidget);
      expect(find.text('August 2026'), findsOneWidget);
    });

    testWidgets('the pill is a compact, high-contrast capsule', (tester) async {
      await pumpSchedule(tester);

      final pill = tester.widget<Container>(
        find.byKey(const Key('calendar_month_pill')),
      );
      final decoration = pill.decoration! as BoxDecoration;
      expect(decoration.borderRadius, isNotNull);
      expect(decoration.color, AppColors.surface800);

      // The header is contained in the calendar card, above the weekday row.
      final headerY = tester.getCenter(find.byType(CalendarMonthHeader)).dy;
      final gridY = tester.getCenter(find.byKey(const Key('day_15'))).dy;
      expect(headerY, lessThan(gridY));
    });

    testWidgets('navigation still works with the redesigned header', (
      tester,
    ) async {
      await pumpSchedule(tester);

      await tester.tap(find.byKey(const Key('next_month_button')));
      await tester.pumpAndSettle();
      expect(find.text('September 2026'), findsOneWidget);

      await tester.tap(find.byKey(const Key('prev_month_button')));
      await tester.pumpAndSettle();
      expect(find.text('August 2026'), findsOneWidget);
    });

    testWidgets('the history popup reuses the same header', (tester) async {
      tester.view.physicalSize = const Size(900, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => showCalendarHistoryDialog(
                    context,
                    repository: MockDailyEntryRepository(),
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.byType(CalendarMonthHeader), findsOneWidget);
      expect(find.byKey(const Key('history_month_label')), findsOneWidget);
    });
  });
}
