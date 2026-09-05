import '../data/daily_log_repository.dart';
import '../models/daily_log.dart';
import '../models/log_parse_response.dart';

/// In-memory test double for [DailyLogRepository].
class MockDailyLogRepository implements DailyLogRepository {
  MockDailyLogRepository({Map<String, String>? seed}) {
    if (seed != null) {
      for (final entry in seed.entries) {
        _store[entry.key] = DailyLog(date: entry.key, text: entry.value);
      }
    }
  }

  final Map<String, DailyLog> _store = {};
  final Map<String, LogParseResponse> _parsedByText = {};

  @override
  Future<DailyLog?> getByDate(String date) async => _store[date];

  @override
  Future<void> save(DailyLog log) async {
    _store[log.date] = log;
  }

  @override
  Future<LogParseResponse?> getByExactText(String text) async =>
      _parsedByText[text];

  @override
  Future<void> saveWithParse(DailyLog log, LogParseResponse parsed) async {
    _store[log.date] = log;
    _parsedByText[log.text] = parsed;
  }

  @override
  Future<List<String>> getAllTexts() async =>
      _store.values.map((log) => log.text).toList();
}