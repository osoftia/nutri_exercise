import '../models/daily_entry.dart';
import '../models/weekly_stat.dart';

/// Estimated calories burned per logged exercise when computing weekly stats.
const int caloriesBurnedPerExercise = 250;

/// Builds the last-7-days energy balance from [entries].
///
/// Days without an entry are zeroed. The window ends at [now] (defaults to the
/// current date) and spans the 6 previous days.
List<WeeklyStat> computeWeeklyStats(List<DailyEntry> entries, {DateTime? now}) {
  final today = now ?? DateTime.now();
  final todayDate = DateTime(today.year, today.month, today.day);
  final byDate = {for (final entry in entries) entry.date: entry};

  final stats = <WeeklyStat>[];
  for (var i = 6; i >= 0; i--) {
    final day = todayDate.subtract(Duration(days: i));
    final key = DailyEntry.dateKey(day);
    final entry = byDate[key];
    stats.add(
      WeeklyStat(
        date: day,
        consumed: entry?.calories ?? 0,
        burned: (entry?.exercises.length ?? 0) * caloriesBurnedPerExercise,
      ),
    );
  }
  return stats;
}