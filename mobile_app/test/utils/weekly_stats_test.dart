import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/models/daily_entry.dart';
import 'package:nutri_mobile_app/core/utils/weekly_stats.dart';

void main() {
  final now = DateTime(2026, 9, 7, 14, 30);

  test('returns seven zeroed days when there is no history', () {
    final stats = computeWeeklyStats([], now: now);

    expect(stats, hasLength(7));
    expect(stats.first.date, DateTime(2026, 9, 1));
    expect(stats.last.date, DateTime(2026, 9, 7));
    for (final stat in stats) {
      expect(stat.consumed, 0);
      expect(stat.burned, 0);
    }
  });

  test('fills consumed calories and burned estimates from entries', () {
    final stats = computeWeeklyStats(
      [
        const DailyEntry(
          date: '2026-09-05',
          calories: 2000,
          exercises: ['Bench Press', 'Squat'],
        ),
        const DailyEntry(date: '2026-09-07', calories: 1500),
      ],
      now: now,
    );

    final sat = stats[4];
    expect(sat.date, DateTime(2026, 9, 5));
    expect(sat.consumed, 2000);
    expect(sat.burned, 2 * caloriesBurnedPerExercise);

    final today = stats[6];
    expect(today.consumed, 1500);
    expect(today.burned, 0);
  });

  test('missing days stay zeroed', () {
    final stats = computeWeeklyStats(
      [const DailyEntry(date: '2026-09-07', calories: 1000)],
      now: now,
    );

    expect(stats[0].consumed, 0);
    expect(stats[6].consumed, 1000);
  });

  test('balance is consumed minus burned', () {
    final stats = computeWeeklyStats(
      [
        const DailyEntry(
          date: '2026-09-07',
          calories: 1000,
          exercises: ['Squat', 'Deadlift'],
        ),
      ],
      now: now,
    );

    expect(
      stats[6].balance,
      1000 - 2 * caloriesBurnedPerExercise,
    );
  });
}