import '../models/daily_log.dart';
import '../models/log_parse_response.dart';

/// Contract for reading and persisting the daily free-text summary and its
/// AI-parsed nutrition result.
abstract interface class DailyLogRepository {
  /// Returns the summary for [date], or `null` when none has been saved.
  Future<DailyLog?> getByDate(String date);

  /// Persists (upserts) the summary for a given date.
  Future<void> save(DailyLog log);

  /// Returns the cached parsed result for an exact [text] match, or `null`.
  Future<LogParseResponse?> getByExactText(String text);

  /// Persists the summary together with its AI-parsed result.
  Future<void> saveWithParse(DailyLog log, LogParseResponse parsed);

  /// Returns the most recent distinct raw texts (for autocomplete).
  Future<List<String>> getAllTexts();
}