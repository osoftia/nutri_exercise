import '../database/database_helper.dart';
import '../models/daily_entry.dart';
import 'daily_entry_repository.dart';

/// SQLite-backed [DailyEntryRepository] storing one entry row per date.
class LocalDailyEntryRepository implements DailyEntryRepository {
  LocalDailyEntryRepository({DatabaseHelper? databaseHelper})
    : _databaseHelper = databaseHelper ?? DatabaseHelper();

  final DatabaseHelper _databaseHelper;

  @override
  Future<DailyEntry?> getByDate(String date) async {
    final row = await _databaseHelper.getDailyEntry(date);
    return row == null ? null : DailyEntry.fromMap(row);
  }

  @override
  Future<List<DailyEntry>> getAll() async {
    final rows = await _databaseHelper.getAllDailyEntries();
    return rows.map(DailyEntry.fromMap).toList();
  }

  @override
  Future<void> save(DailyEntry entry) =>
      _databaseHelper.upsertDailyEntry(entry);

  @override
  Future<void> delete(String date) => _databaseHelper.deleteDailyEntry(date);
}