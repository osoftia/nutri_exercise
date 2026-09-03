import '../data/daily_log_repository.dart';
import '../models/daily_log.dart';

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

  @override
  Future<DailyLog?> getByDate(String date) async => _store[date];

  @override
  Future<void> save(DailyLog log) async {
    _store[log.date] = log;
  }
}
