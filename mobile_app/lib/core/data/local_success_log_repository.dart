import '../database/database_helper.dart';
import '../models/success_log_entry.dart';
import 'success_log_repository.dart';

/// SQLite implementation of [SuccessLogRepository].
class LocalSuccessLogRepository implements SuccessLogRepository {
  LocalSuccessLogRepository({DatabaseHelper? databaseHelper})
      : _databaseHelper = databaseHelper ?? DatabaseHelper();

  final DatabaseHelper _databaseHelper;

  @override
  Future<void> record(SuccessLogEntry entry) =>
      _databaseHelper.insertSuccessLog(entry);

  @override
  Future<List<SuccessLogEntry>> getAll() => _databaseHelper.getSuccessLogs();
}
