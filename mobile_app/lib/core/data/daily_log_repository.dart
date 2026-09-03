import '../models/daily_log.dart';

/// Contract for reading and persisting the daily free-text summary.
abstract interface class DailyLogRepository {
  /// Returns the summary for [date], or `null` when none has been saved.
  Future<DailyLog?> getByDate(String date);

  /// Persists (upserts) the summary for a given date.
  Future<void> save(DailyLog log);
}
