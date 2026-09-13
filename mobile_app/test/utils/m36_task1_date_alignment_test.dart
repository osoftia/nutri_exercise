import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/mocks/mock_daily_entry_repository.dart';
import 'package:nutri_mobile_app/core/models/daily_entry.dart';
import 'package:nutri_mobile_app/core/state/daily_entry_controller.dart';
import 'package:nutri_mobile_app/core/utils/weekly_stats.dart';

void main() {
  group('weekdayLabel (M36 Task 1)', () {
    test('maps Monday-first weekdays to single letters', () {
      // 2026-01-01 was a Thursday (anchor).
      expect(DateTime(2026, 1, 1).weekday, DateTime.thursday);
      expect(weekdayLabel(DateTime(2026, 1, 1)), 'T');
      expect(weekdayLabel(DateTime(2026, 1, 5)), 'M'); // Monday
      expect(weekdayLabel(DateTime(2026, 1, 10)), 'S'); // Saturday
      expect(weekdayLabel(DateTime(2026, 1, 11)), 'S'); // Sunday
    });

    test('agrees with DateTime.weekday for a full month', () {
      const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
      for (var day = 1; day <= 28; day++) {
        final date = DateTime(2026, 2, day);
        expect(weekdayLabel(date), labels[date.weekday - 1]);
      }
    });
  });

  group('computeWeeklyStats window (M36 Task 1)', () {
    test('spans month boundaries with exact date keys', () {
      final stats = computeWeeklyStats(
        const [DailyEntry(date: '2026-02-27', calories: 1800)],
        now: DateTime(2026, 3, 2, 23, 30), // late night must still key today
      );

      expect(stats, hasLength(7));
      expect(stats.first.date, DateTime(2026, 2, 24));
      expect(stats.last.date, DateTime(2026, 3, 2));
      // The 2026-02-27 entry lands on its exact day, not a neighbour.
      final feb27 = stats.firstWhere(
        (s) => s.date == DateTime(2026, 2, 27),
      );
      expect(feb27.consumed, 1800);
      expect(
        stats.where((s) => s.consumed != 0),
        hasLength(1),
      );
    });

    test('each stat date keys back to its own YYYY-MM-DD entry', () {
      final now = DateTime(2026, 9, 7, 14, 30);
      final stats = computeWeeklyStats([], now: now);
      for (var i = 0; i < 7; i++) {
        final expected = DateTime(2026, 9, 1 + i);
        expect(stats[i].date, expected);
        expect(DailyEntry.dateKey(stats[i].date), '2026-09-0${1 + i}');
      }
    });
  });

  group('DailyEntryController.entryForDate (M36 Task 1)', () {
    test('resolves the exact day and rejects lookalikes', () async {
      final controller = DailyEntryController(
        repository: MockDailyEntryRepository({
          '2026-09-10': const DailyEntry(date: '2026-09-10', calories: 500),
          '2026-09-11': const DailyEntry(date: '2026-09-11', calories: 700),
        }),
      );
      await controller.loadAll();

      expect(controller.entryForDate('2026-09-10')?.calories, 500);
      expect(controller.entryForDate('2026-09-11')?.calories, 700);
      // No prefix/day-padding/index drift: lookalikes miss.
      expect(controller.entryForDate('2026-09-1'), isNull);
      expect(controller.entryForDate('2026-09-12'), isNull);
      expect(controller.entryForDate('2026-09'), isNull);
      expect(controller.entryForDate(''), isNull);
    });
  });
}
