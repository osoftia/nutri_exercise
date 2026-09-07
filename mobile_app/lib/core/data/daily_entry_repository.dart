import '../models/daily_entry.dart';

/// Contract for reading and persisting per-day nutrition + exercise entries
/// used by the calendar history.
abstract interface class DailyEntryRepository {
  /// Returns the entry for [date], or `null` when none has been saved.
  Future<DailyEntry?> getByDate(String date);

  /// Returns every stored entry (for the calendar history view).
  Future<List<DailyEntry>> getAll();

  /// Persists (upserts) an entry for a given date.
  Future<void> save(DailyEntry entry);

  /// Removes the entry for [date], if any.
  Future<void> delete(String date);
}