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

void main() {
  String dateKey(int day) {
    final now = DateTime.now();
    final date = DateTime(now.year, now.month, day);
    return DailyEntry.dateKey(date);
  }

  testWidgets('calendar marks days that have entries', (tester) async {
    final day3 = dateKey(3);
    final repo = _FakeDailyEntryRepository({
      day3: DailyEntry(date: day3, calories: 2100, exercises: const ['Squat']),
    });

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

    expect(find.byKey(Key('calendar_day_$day3')), findsOneWidget);
    expect(find.byIcon(Icons.circle), findsWidgets);

    await tester.tap(find.byKey(Key('calendar_day_$day3')));
    await tester.pumpAndSettle();

    expect(find.text('2100'), findsOneWidget);
    expect(find.text('Squat'), findsOneWidget);
  });

  testWidgets('an entry can be edited and saved back', (tester) async {
    final repo = _FakeDailyEntryRepository();
    final day = dateKey(5);

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

    await tester.tap(find.byKey(Key('calendar_day_$day')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('history_calories_field')),
      '2500',
    );
    await tester.enterText(
      find.byKey(const Key('history_exercises_field')),
      'Bench Press, Squat',
    );
    await tester.tap(find.byKey(const Key('history_save_button')));
    await tester.pumpAndSettle();

    final saved = await repo.getByDate(day);
    expect(saved, isNotNull);
    expect(saved!.calories, 2500);
    expect(saved.exercises, ['Bench Press', 'Squat']);
  });

  testWidgets('an entry can be deleted', (tester) async {
    final repo = _FakeDailyEntryRepository({
      dateKey(7): DailyEntry(date: dateKey(7), calories: 900),
    });

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

    await tester.tap(find.byKey(Key('calendar_day_${dateKey(7)}')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('history_delete_button')));
    await tester.pumpAndSettle();

    expect(await repo.getByDate(dateKey(7)), isNull);
  });
}