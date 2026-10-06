import '../models/error_log_entry.dart';

/// Local persistence contract for technical failures captured by the app.
abstract interface class ErrorLogRepository {
  Future<void> record(ErrorLogEntry entry);

  Future<List<ErrorLogEntry>> getAll();
}
