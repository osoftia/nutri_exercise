import '../database/database_helper.dart';
import '../models/daily_log.dart';
import 'daily_log_repository.dart';

/// SQLite-backed [DailyLogRepository] storing one summary row per date.
class LocalDailyLogRepository implements DailyLogRepository {
  LocalDailyLogRepository({DatabaseHelper? databaseHelper})
    : _databaseHelper = databaseHelper ?? DatabaseHelper();

  final DatabaseHelper _databaseHelper;

  @override
  Future<DailyLog?> getByDate(String date) async {
    final row = await _databaseHelper.getDailyLog(date);
    return row == null ? null : DailyLog.fromMap(row);
  }

  @override
  Future<void> save(DailyLog log) async {
    await _databaseHelper.upsertDailyLog(log);
  }
}
