import 'dart:convert';

import '../database/database_helper.dart';
import '../models/daily_log.dart';
import '../models/log_parse_response.dart';
import 'daily_log_repository.dart';

/// SQLite-backed [DailyLogRepository] storing one summary row per date, with
/// the AI-parsed JSON cached alongside the raw text.
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

  @override
  Future<LogParseResponse?> getByExactText(String text) async {
    final row = await _databaseHelper.getDailyLogByText(text);
    if (row == null) return null;
    final raw = row['parsed_json'] as String?;
    if (raw == null || raw.isEmpty) return null;
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) return null;
    return LogParseResponse.fromJson(decoded);
  }

  @override
  Future<void> saveWithParse(DailyLog log, LogParseResponse parsed) async {
    await _databaseHelper.upsertDailyLog(
      log,
      parsedJson: jsonEncode(parsed.toJson()),
    );
  }

  @override
  Future<List<String>> getAllTexts() async {
    return _databaseHelper.getAllDailyLogTexts();
  }
}