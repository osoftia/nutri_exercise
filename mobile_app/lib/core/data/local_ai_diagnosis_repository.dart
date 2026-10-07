import 'dart:convert';

import '../database/database_helper.dart';
import '../models/ai_diagnosis.dart';
import 'ai_diagnosis_store.dart';

/// SQLite-backed offline storage for AI reports, menus, and meal preferences.
class LocalAiDiagnosisRepository implements AiDiagnosisStore {
  LocalAiDiagnosisRepository({DatabaseHelper? databaseHelper})
      : _databaseHelper = databaseHelper ?? DatabaseHelper();

  static const String foodPreferencesKey = 'ai_diagnosis_food_preferences';

  final DatabaseHelper _databaseHelper;

  @override
  Future<void> save(AiDiagnosisReport report) async {
    await _databaseHelper.insertAiDiagnosis(report);
  }

  @override
  Future<AiDiagnosisReport?> latest() async {
    final reports = await all();
    return reports.isEmpty ? null : reports.first;
  }

  @override
  Future<List<AiDiagnosisReport>> all() async {
    final rows = await _databaseHelper.getAiDiagnoses();
    final reports = <AiDiagnosisReport>[];
    for (final row in rows) {
      final id = row['id'] as int;
      final menuRows = await _databaseHelper.getAiSuggestedMenus(id);
      reports.add(
        AiDiagnosisReport(
          id: id,
          createdAt: DateTime.parse(row['created_at'] as String),
          title: row['title'] as String,
          summary: row['summary'] as String,
          considerations: AiDiagnosisReport.decodeStringList(
            row['considerations_json'] as String,
          ),
          conditionIds: AiDiagnosisReport.decodeStringList(
            row['condition_ids_json'] as String,
          ),
          foodPreferences: row['food_preferences'] as String,
          language: row['language'] as String,
          responseJson: row['response_json'] as String? ?? '',
          menus: menuRows.map(_mapMenu).toList(growable: false),
        ),
      );
    }
    return reports;
  }

  AiSuggestedMenu _mapMenu(Map<String, Object?> row) {
    final meals = jsonDecode(row['meals_json'] as String) as List<dynamic>;
    return AiSuggestedMenu(
      id: row['id'] as int,
      diagnosisId: row['diagnosis_id'] as int,
      name: row['name'] as String,
      day: row['day'] as String,
      meals: meals.map(AiSuggestedMeal.fromJson).toList(growable: false),
    );
  }

  @override
  Future<String> loadFoodPreferences() async =>
      await _databaseHelper.getSetting(foodPreferencesKey) ?? '';

  @override
  Future<void> saveFoodPreferences(String preferences) =>
      _databaseHelper.upsertSetting(foodPreferencesKey, preferences.trim());
}
