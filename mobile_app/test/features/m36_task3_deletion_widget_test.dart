import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/data/daily_entry_repository.dart';
import 'package:nutri_mobile_app/core/models/daily_entry.dart';
import 'package:nutri_mobile_app/core/theme/app_theme.dart';
import 'package:nutri_mobile_app/ui/organisms/calendar_history_dialog.dart';

class _FakeDailyEntryRepository implements DailyEntryRepository {
  _FakeDailyEntryRepository([Map<String, DailyEntry>? seed])
    : _store = {...?seed};

  final Map<String, DailyEntry> _store;

  @override
  Future<DailyEntry?> getByDate(String date) async => _store[date];

  @override
  Future<List<DailyEntry>> getAll() async => _store.values.toList();

  @override
  Future<void> save(DailyEntry entry) async => _store[entry.date] = entry;

  @override
  Future<void> delete(String date) async => _store.remove(date);
}

String _dayKey(int day) {
  final now = DateTime.now();
  return DailyEntry.dateKey(DateTime(now.year, now.month, day));
}

Future<void> _openCalendar(
  WidgetTester tester,
  DailyEntryRepository repo, {
  VoidCallback? onChanged,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => showCalendarHistoryDialog(
                context,
                repository: repo,
                onChanged: onChanged,
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
}

void main() {
  group('entry deletion control (M36 Task 3)', () {
    testWidgets('delete control is prominent: trash icon + Delete Record', (
      tester,
    ) async {
      final day = _dayKey(7);
      final repo = _FakeDailyEntryRepository({
        day: DailyEntry(date: day, calories: 900),
      });

      await _openCalendar(tester, repo);
      await tester.tap(find.byKey(Key('calendar_day_$day')));
      await tester.pumpAndSettle();

      final deleteButton = find.byKey(const Key('history_delete_button'));
      expect(deleteButton, findsOneWidget);
      expect(
        find.descendant(
          of: deleteButton,
          matching: find.byIcon(Icons.delete_outline),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: deleteButton,
          matching: find.text('Delete Record'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('delete removes the row and instantly clears the grid dot', (
      tester,
    ) async {
      final day = _dayKey(7);
      final repo = _FakeDailyEntryRepository({
        day: DailyEntry(date: day, calories: 900),
      });
      var changedCalls = 0;

      await _openCalendar(
        tester,
        repo,
        onChanged: () => changedCalls++,
      );

      final dayCell = find.byKey(Key('calendar_day_$day'));
      expect(
        find.descendant(of: dayCell, matching: find.byIcon(Icons.circle)),
        findsOneWidget,
        reason: 'day starts marked',
      );

      await tester.tap(dayCell);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('history_delete_button')));
      await tester.pumpAndSettle();

      // Row gone from storage …
      expect(await repo.getByDate(day), isNull);
      // … editor closed …
      expect(find.byKey(const Key('history_entry_editor')), findsNothing);
      // … and the grid dot is gone WITHOUT reopening the calendar.
      expect(
        find.descendant(
          of: find.byKey(Key('calendar_day_$day')),
          matching: find.byIcon(Icons.circle),
        ),
        findsNothing,
      );
      // Host hook fired so streak/stats state can refresh.
      expect(changedCalls, 1);
    });

    testWidgets('save fires onChanged so dependent state refreshes', (
      tester,
    ) async {
      final day = _dayKey(5);
      final repo = _FakeDailyEntryRepository();
      var changedCalls = 0;

      await _openCalendar(
        tester,
        repo,
        onChanged: () => changedCalls++,
      );

      await tester.tap(find.byKey(Key('calendar_day_$day')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('history_calories_field')),
        '2500',
      );
      await tester.tap(find.byKey(const Key('history_save_button')));
      await tester.pumpAndSettle();

      expect((await repo.getByDate(day))?.calories, 2500);
      expect(changedCalls, 1);
    });
  });
}
