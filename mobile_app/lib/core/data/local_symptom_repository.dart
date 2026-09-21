import '../database/database_helper.dart';
import '../models/symptom_log.dart';
import 'symptom_repository.dart';

/// SQLite-backed [SymptomRepository] storing one row per date + symptom.
class LocalSymptomRepository implements SymptomRepository {
  LocalSymptomRepository({DatabaseHelper? databaseHelper})
    : _databaseHelper = databaseHelper ?? DatabaseHelper();

  final DatabaseHelper _databaseHelper;

  @override
  Future<List<SymptomLog>> getForDate(String date) async {
    final rows = await _databaseHelper.getSymptomLogs(date);
    return rows.map(SymptomLog.fromMap).toList();
  }

  @override
  Future<List<SymptomLog>> getAll() async {
    final rows = await _databaseHelper.getAllSymptomLogs();
    return rows.map(SymptomLog.fromMap).toList();
  }

  @override
  Future<void> save(SymptomLog log) => _databaseHelper.upsertSymptomLog(log);
}
