import '../database/database_helper.dart';
import '../models/error_log_entry.dart';
import 'error_log_repository.dart';

/// SQLite implementation of [ErrorLogRepository].
class LocalErrorLogRepository implements ErrorLogRepository {
  LocalErrorLogRepository({DatabaseHelper? databaseHelper})
      : _databaseHelper = databaseHelper ?? DatabaseHelper();

  final DatabaseHelper _databaseHelper;

  @override
  Future<void> record(ErrorLogEntry entry) =>
      _databaseHelper.insertErrorLog(entry);

  @override
  Future<List<ErrorLogEntry>> getAll() => _databaseHelper.getErrorLogs();
}
