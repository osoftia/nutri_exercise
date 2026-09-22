import '../models/daily_entry.dart';
import '../models/weekly_stat.dart';

/// Estimated calories burned per logged exercise when computing weekly stats.
const int caloriesBurnedPerExercise = 250;

/// Single-letter Monday-first weekday label for [date] (`M T W T F S S`).
///
/// M36 Task 1: labels must be derived from the actual date, never zipped
/// from a static list over a rolling window.
String weekdayLabel(DateTime date) {
  const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  return labels[date.weekday - 1];
}

/// Builds the last-7-days energy balance from [entries].
///
/// Days without an entry are zeroed. The window ends at [now] (defaults to the
/// current date) and spans the 6 previous days.
///
/// M36 Task 1: days are stepped with calendar arithmetic
/// (`DateTime(y, m, d - i)`) instead of `subtract(Duration(days: i))` so a
/// DST transition (23/25-hour day) can never shift the wall date and
/// mis-attribute an entry to the wrong day.
List<WeeklyStat> computeWeeklyStats(List<DailyEntry> entries, {DateTime? now}) {
  final today = now ?? DateTime.now();
  final todayDate = DateTime(today.year, today.month, today.day);
  final byDate = {for (final entry in entries) entry.date: entry};

  final stats = <WeeklyStat>[];
  for (var i = 6; i >= 0; i--) {
    final day = DateTime(todayDate.year, todayDate.month, todayDate.day - i);
    final key = DailyEntry.dateKey(day);
    final entry = byDate[key];
    stats.add(
      WeeklyStat(
        date: day,
        consumed: entry?.calories ?? 0,
        burned: _burnedFor(entry),
        protein: entry?.protein ?? 0,
        carbs: entry?.carbs ?? 0,
        fat: entry?.fat ?? 0,
      ),
    );
  }
  return stats;
}

/// The calories burned on a day.
///
/// The persisted [DailyEntry.burned] (recorded by an exercise check-in or an
/// in-app workout confirmation) is authoritative; only when it is absent do we
/// fall back to the flat per-exercise estimate. This keeps the historical
/// summary consistent with the post-workout popup instead of silently
/// recomputing a different number.
int _burnedFor(DailyEntry? entry) {
  if (entry == null) return 0;
  if (entry.burned > 0) return entry.burned;
  return entry.exercises.length * caloriesBurnedPerExercise;
}