import '../models/success_log_entry.dart';

/// Local persistence contract for successful backend exchanges captured by the
/// app.
abstract interface class SuccessLogRepository {
  Future<void> record(SuccessLogEntry entry);

  Future<List<SuccessLogEntry>> getAll();
}
