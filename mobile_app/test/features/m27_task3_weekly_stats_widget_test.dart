import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/app.dart';
import 'package:nutri_mobile_app/core/config/app_config.dart';
import 'package:nutri_mobile_app/core/data/daily_entry_repository.dart';
import 'package:nutri_mobile_app/core/models/daily_entry.dart';
import 'package:nutri_mobile_app/core/models/weekly_stat.dart';
import 'package:nutri_mobile_app/core/theme/app_theme.dart';
import 'package:nutri_mobile_app/core/utils/weekly_stats.dart';
import 'package:nutri_mobile_app/ui/organisms/weekly_stats_sheet.dart';

class _FakeRepo implements DailyEntryRepository {
  _FakeRepo(this.entries);
  final List<DailyEntry> entries;

  @override
  Future<void> delete(String date) async {}

  @override
  Future<List<DailyEntry>> getAll() async => entries;

  @override
  Future<DailyEntry?> getByDate(String date) async => null;

  @override
  Future<void> save(DailyEntry entry) async {}
}

void main() {
  testWidgets('weekly stats sheet renders totals and the animated chart', (
    tester,
  ) async {
    final repo = _FakeRepo([
      DailyEntry(
        date: DailyEntry.dateKey(DateTime.now()),
        calories: 2000,
        exercises: const ['Bench Press', 'Squat'],
      ),
    ]);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showWeeklyStatsSheet(context, repository: repo),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('weekly_stats_sheet')), findsOneWidget);
    expect(find.text('Weekly Stats'), findsOneWidget);
    expect(find.byKey(const Key('weekly_bar_consumed_6')), findsOneWidget);
    expect(find.byKey(const Key('weekly_bar_burned_6')), findsOneWidget);
  });

  testWidgets('weekly stats AppBar action opens the sheet', (tester) async {
    tester.view.physicalSize = const Size(1000, 6000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      NutriApp(config: const AppConfig(name: 'dev', useMocks: true)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('weekly_stats_action')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('weekly_stats_sheet')), findsOneWidget);
  });

  test('computeWeeklyStats exposes per-day stats with balance', () {
    final stats = computeWeeklyStats(
      [
        DailyEntry(
          date: DailyEntry.dateKey(DateTime.now()),
          calories: 1500,
          exercises: const ['Squat'],
        ),
      ],
    );

    expect(stats, hasLength(7));
    final today = stats.last;
    expect(today, isA<WeeklyStat>());
    expect(today.consumed, 1500);
    expect(today.burned, caloriesBurnedPerExercise);
  });
}