import '../data/error_log_repository.dart';
import '../models/error_log_entry.dart';

/// In-memory forensic log used by mock flavors and widget tests.
class MockErrorLogRepository implements ErrorLogRepository {
  final List<ErrorLogEntry> _entries = [];

  @override
  Future<List<ErrorLogEntry>> getAll() async =>
      List.unmodifiable(_entries.reversed);

  @override
  Future<void> record(ErrorLogEntry entry) async {
    _entries.add(entry);
  }
}
