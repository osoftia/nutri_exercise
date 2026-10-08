import '../data/success_log_repository.dart';
import '../models/success_log_entry.dart';

/// In-memory forensic success log used by mock flavors and widget tests.
class MockSuccessLogRepository implements SuccessLogRepository {
  final List<SuccessLogEntry> _entries = [];

  @override
  Future<List<SuccessLogEntry>> getAll() async =>
      List.unmodifiable(_entries.reversed);

  @override
  Future<void> record(SuccessLogEntry entry) async {
    _entries.add(entry);
  }
}
