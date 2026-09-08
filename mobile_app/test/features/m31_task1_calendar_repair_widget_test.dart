import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/data/daily_entry_repository.dart';
import 'package:nutri_mobile_app/core/models/daily_entry.dart';
import 'package:nutri_mobile_app/core/theme/app_theme.dart';
import 'package:nutri_mobile_app/ui/atoms/typography.dart';
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

String today() => DailyEntry.dateKey(DateTime.now());

Future<void> _openCalendar(WidgetTester tester, DailyEntryRepository repo) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => showCalendarHistoryDialog(context, repository: repo),
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
  testWidgets('calendar renders cleanly on a narrow phone screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final repo = _FakeDailyEntryRepository({
      today(): const DailyEntry(date: '', calories: 500, exercises: ['Squat']),
    });
    final seeded = (await repo.getByDate(today()))!;
    repo.save(DailyEntry(
      date: today(),
      calories: seeded.calories,
      exercises: seeded.exercises,
    ));

    await _openCalendar(tester, repo);

    expect(find.byKey(const Key('calendar_history_dialog')), findsOneWidget);
    expect(find.byKey(Key('calendar_day_${today()}')), findsOneWidget);
    expect(find.byKey(const Key('history_prev_month')), findsOneWidget);
  });

  testWidgets('calendar renders cleanly on a large screen', (tester) async {
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _openCalendar(tester, _FakeDailyEntryRepository());

    expect(find.byKey(const Key('calendar_history_dialog')), findsOneWidget);
  });

  testWidgets('month navigation updates the label without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _openCalendar(tester, _FakeDailyEntryRepository());

    final labelBefore = tester
        .widget<AppText>(find.byKey(const Key('history_month_label')))
        .text;

    await tester.tap(find.byKey(const Key('history_next_month')));
    await tester.pumpAndSettle();

    final labelAfter = tester
        .widget<AppText>(find.byKey(const Key('history_month_label')))
        .text;

    expect(labelAfter, isNot(labelBefore));
  });
}