import '../data/daily_entry_repository.dart';
import '../models/daily_entry.dart';

/// In-memory [DailyEntryRepository] used by tests and mock builds.
class MockDailyEntryRepository implements DailyEntryRepository {
  MockDailyEntryRepository([Map<String, DailyEntry>? seed])
    : _store = {...?seed};

  final Map<String, DailyEntry> _store;

  @override
  Future<DailyEntry?> getByDate(String date) async => _store[date];

  @override
  Future<List<DailyEntry>> getAll() async => _store.values.toList();

  @override
  Future<void> save(DailyEntry entry) async => _store[entry.date] = entry;

  @override
  Future<void> delete(String date) async => _store.remove(date);
}