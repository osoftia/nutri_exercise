import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/mocks/mock_daily_entry_repository.dart';
import 'package:nutri_mobile_app/core/models/daily_entry.dart';
import 'package:nutri_mobile_app/core/theme/app_theme.dart';
import 'package:nutri_mobile_app/core/utils/weekly_stats.dart';
import 'package:nutri_mobile_app/ui/organisms/calendar_history_dialog.dart';
import 'package:nutri_mobile_app/ui/organisms/weekly_stats_sheet.dart';

Future<void> _openCalendar(
  WidgetTester tester,
  MockDailyEntryRepository repo,
) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () =>
                  showCalendarHistoryDialog(context, repository: repo),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  group('calendar day X opens exactly day X (M36 Task 1)', () {
    testWidgets('seeded day shows its own entry values', (tester) async {
      final now = DateTime.now();
      final firstOfMonth = DateTime(now.year, now.month, 1);
      final key = DailyEntry.dateKey(firstOfMonth);
      final repo = MockDailyEntryRepository({
        key: DailyEntry(date: key, calories: 1234, protein: 56),
      });

      await _openCalendar(tester, repo);

      await tester.tap(find.byKey(Key('calendar_day_$key')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('history_entry_editor')), findsOneWidget);
      expect(find.text('Edit $key'), findsOneWidget);
      // The editor displays the tapped day's own stored values.
      final caloriesField = tester.widget<TextField>(
        find.byKey(const Key('history_calories_field')),
      );
      expect(caloriesField.controller!.text, '1234');
    });

    testWidgets('empty day opens a blank editor for that same date', (
      tester,
    ) async {
      final now = DateTime.now();
      final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
      // Pick a day guaranteed to differ from any seed (no seeds at all).
      final day = daysInMonth >= 15 ? 15 : daysInMonth;
      final key = DailyEntry.dateKey(DateTime(now.year, now.month, day));
      final repo = MockDailyEntryRepository();

      await _openCalendar(tester, repo);

      await tester.tap(find.byKey(Key('calendar_day_$key')));
      await tester.pumpAndSettle();

      expect(find.text('Edit $key'), findsOneWidget);
      final caloriesField = tester.widget<TextField>(
        find.byKey(const Key('history_calories_field')),
      );
      expect(caloriesField.controller!.text, isEmpty);
      // No delete control without an existing entry.
      expect(find.byKey(const Key('history_delete_button')), findsNothing);
    });
  });

  testWidgets('weekly chart labels match the real weekdays', (tester) async {
    final todayKey = DailyEntry.dateKey(DateTime.now());
    final repo = MockDailyEntryRepository({
      todayKey: DailyEntry(date: todayKey, calories: 2000),
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () =>
                    showWeeklyStatsSheet(context, repository: repo),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // Every bar caption equals the weekday letter of its exact stat date.
    final stats = computeWeeklyStats(await repo.getAll());
    for (final stat in stats) {
      expect(find.text(weekdayLabel(stat.date)), findsWidgets);
    }
  });
}
