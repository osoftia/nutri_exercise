import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/data/daily_entry_repository.dart';
import 'package:nutri_mobile_app/core/mocks/mock_daily_entry_repository.dart';
import 'package:nutri_mobile_app/core/models/daily_entry.dart';
import 'package:nutri_mobile_app/core/theme/app_theme.dart';
import 'package:nutri_mobile_app/ui/molecules/calendar_month_header.dart';
import 'package:nutri_mobile_app/ui/organisms/calendar_history_dialog.dart';

class _FakeRepo implements DailyEntryRepository {
  _FakeRepo([Map<String, DailyEntry>? seed]) : _store = {...?seed};
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
  String dayKey(int day) {
    final now = DateTime.now();
    return DailyEntry.dateKey(DateTime(now.year, now.month, day));
  }

  Future<void> openHistory(WidgetTester tester, DailyEntryRepository repo) async {
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
  }

  group('M46 centralized history popup', () {
    testWidgets('renders as a centered dialog, not a bottom sheet', (
      tester,
    ) async {
      await openHistory(tester, _FakeRepo());

      expect(find.byKey(const Key('calendar_history_dialog')), findsOneWidget);
      expect(find.byType(Dialog), findsOneWidget);
      expect(find.byType(BottomSheet), findsNothing);

      // Centered on screen (within a small tolerance).
      final center = tester.getCenter(
        find.byKey(const Key('calendar_history_dialog')),
      );
      final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
      expect((center.dx - screen.width / 2).abs(), lessThan(4));
      expect((center.dy - screen.height / 2).abs(), lessThan(40));
    });

    testWidgets('uses the clean calendar month header', (tester) async {
      await openHistory(tester, _FakeRepo());

      expect(find.byType(CalendarMonthHeader), findsOneWidget);
      expect(find.byKey(const Key('calendar_month_pill')), findsOneWidget);
    });

    testWidgets('the day editor opens as a centered dialog too', (tester) async {
      final day = dayKey(9);
      await openHistory(
        tester,
        _FakeRepo({day: DailyEntry(date: day, calories: 1200)}),
      );

      await tester.tap(find.byKey(Key('calendar_day_$day')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('history_entry_editor')), findsOneWidget);
      expect(find.byType(Dialog), findsNWidgets(2));
    });
  });
}
