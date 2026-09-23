import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/data/daily_entry_repository.dart';
import 'package:nutri_mobile_app/core/models/daily_entry.dart';
import 'package:nutri_mobile_app/core/theme/app_theme.dart';
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
  Future<void> pumpSheet(WidgetTester tester, DailyEntryRepository repo) async {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

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
  }

  group('M47 weekly stats overlaid macro bar', () {
    testWidgets('overlays protein and fat metrics on the chart', (tester) async {
      await pumpSheet(
        tester,
        _FakeRepo([
          DailyEntry(
            date: DailyEntry.dateKey(DateTime.now()),
            calories: 2000,
            protein: 130,
            carbs: 210,
            fat: 62,
            exercises: const ['Bench Press'],
          ),
        ]),
      );

      // The macro overlay is a single bar sitting over/with the chart.
      final overlay = find.byKey(const Key('weekly_macro_overlay'));
      expect(overlay, findsOneWidget);

      // Protein and fat are shown in the overlay.
      expect(find.byKey(const Key('weekly_protein_overlay')), findsOneWidget);
      expect(find.byKey(const Key('weekly_fat_overlay')), findsOneWidget);
      expect(find.text('130g'), findsWidgets);
      expect(find.text('62g'), findsWidgets);

      // The overlay sits above the balance chart in the layout.
      final overlayY = tester.getCenter(overlay).dy;
      final chartY = tester
          .getCenter(find.byKey(const Key('weekly_bar_consumed_6')))
          .dy;
      expect(overlayY, lessThan(chartY));
    });

    testWidgets('the old standalone macro tile row is gone', (tester) async {
      await pumpSheet(tester, _FakeRepo([]));

      expect(find.byKey(const Key('weekly_carbs_total')), findsNothing);
    });
  });
}
