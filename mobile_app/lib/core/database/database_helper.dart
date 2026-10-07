import 'dart:convert';

import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/daily_entry.dart';
import '../models/daily_log.dart';
import '../models/error_log_entry.dart';
import '../models/diet_models.dart';
import '../models/ai_diagnosis.dart';
import '../models/meal_action.dart';
import '../models/projection_models.dart';
import '../models/routine_models.dart';
import '../models/symptom_log.dart';
import '../models/tamagotchi_progress.dart';
import '../models/user_profile.dart';
import 'database_schema.dart';

/// Local SQLite storage for offline-first persistence of routines and diets.
///
/// A [database] override can be provided (e.g. an in-memory database in tests).
/// Table creation and migrations are delegated to [DatabaseSchema].
class DatabaseHelper {
  DatabaseHelper({Database? database}) : _databaseOverride = database;

  static const int _dbVersion = DatabaseSchema.version;

  final Database? _databaseOverride;
  Database? _database;

  Future<Database> get database async {
    final override = _databaseOverride;
    if (override != null) return override;
    final existing = _database;
    if (existing != null) return existing;
    final dir = await getApplicationDocumentsDirectory();
    _database = await openDatabase(
      '${dir.path}/${DatabaseSchema.fileName}',
      version: _dbVersion,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: DatabaseSchema.createAll,
      onUpgrade: DatabaseSchema.upgrade,
    );
    return _database!;
  }

  /// Adds the `mass_json` column to `tamagotchi_progress` (version 10).
  ///
  /// Re-exported from [DatabaseSchema] so the legacy-schema upgrade path stays
  /// testable.
  static Future<void> ensureTamagotchiMassColumn(Database db) =>
      // ignore: invalid_use_of_visible_for_testing_member
      DatabaseSchema.ensureTamagotchiMassColumn(db);

  Future<List<Map<String, Object?>>> getRoutines() async {
    final db = await database;
    return db.query('routines', orderBy: 'id');
  }

  /// Returns the exercises of [routineId] by decoding its `exercises_json`.
  Future<List<Map<String, Object?>>> getExercisesForRoutine(
    int routineId,
  ) async {
    final db = await database;
    final rows = await db.query(
      'routines',
      where: 'id = ?',
      whereArgs: [routineId],
    );
    if (rows.isEmpty) return const [];
    final raw = rows.first['exercises_json'] as String?;
    if (raw == null || raw.isEmpty) return const [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((exercise) => Map<String, Object?>.from(exercise as Map))
        .toList();
  }

  /// Saves (upserts) a workout day and its exercises.
  ///
  /// [isGenerated] is accepted for API compatibility but is not persisted
  /// (the `routines` table has no generated flag).
  Future<void> saveWorkoutDay(WorkoutDay day, {bool isGenerated = false}) {
    return upsertRoutine(day);
  }

  /// Removes every routine row.
  Future<void> clearAll() async {
    final db = await database;
    await db.delete('routines');
  }

  Future<List<Map<String, Object?>>> getDiets() async {
    final db = await database;
    return db.query('diets', orderBy: 'id');
  }

  Future<void> upsertRoutine(WorkoutDay day) async {
    final db = await database;
    await db.insert('routines', {
      'id': day.id,
      'weekday': day.weekday,
      'focus': day.focus,
      'exercises_json': jsonEncode(
        day.exercises.map((exercise) => exercise.toJson()).toList(),
      ),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> upsertDiet(DailyMenu menu) async {
    final db = await database;
    await db.insert('diets', {
      'id': menu.id,
      'date': menu.date,
      'total_calories': menu.totalCalories,
      'meals_json': jsonEncode(
        menu.meals.map((meal) => meal.toJson()).toList(),
      ),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Returns the most frequent meal names whose `mealType` matches
  /// [mealType] (e.g. `lunch`), ordered by frequency, up to [limit].
  ///
  /// Meal names are decoded from the `meals_json` column of the `diets` table.
  Future<List<String>> getTopMealsByType(
    String mealType, {
    int limit = 3,
  }) async {
    final db = await database;
    final rows = await db.query('diets', columns: ['meals_json']);
    final frequencies = <String, int>{};
    for (final row in rows) {
      final raw = row['meals_json'] as String?;
      if (raw == null || raw.isEmpty) continue;
      final decoded = jsonDecode(raw);
      if (decoded is! List) continue;
      for (final meal in decoded) {
        if (meal is! Map) continue;
        if (meal['mealType'] != mealType) continue;
        final name = meal['name'] as String?;
        if (name == null || name.isEmpty) continue;
        frequencies[name] = (frequencies[name] ?? 0) + 1;
      }
    }
    final ranked = frequencies.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return ranked.take(limit).map((entry) => entry.key).toList();
  }

  Future<List<Map<String, Object?>>> getNotificationPrefs() async {
    final db = await database;
    return db.query('notification_prefs');
  }

  Future<void> upsertNotificationPref(String key, bool enabled) async {
    final db = await database;
    await db.insert('notification_prefs', {
      'pref_key': key,
      'enabled': enabled ? 1 : 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Returns the daily summary row for [date], or `null` when none is saved.
  Future<Map<String, Object?>?> getDailyLog(String date) async {
    final db = await database;
    final rows = await db.query(
      'daily_logs',
      where: 'date = ?',
      whereArgs: [date],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  /// Upserts the daily summary for [log.date] (one row per date), optionally
  /// storing the AI-parsed JSON alongside the raw text.
  Future<void> upsertDailyLog(DailyLog log, {String? parsedJson}) async {
    final db = await database;
    await db.insert(
      'daily_logs',
      {
        'date': log.date,
        'text': log.text,
        if (parsedJson != null) 'parsed_json': parsedJson,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Returns the row whose raw text exactly matches [text], or `null`.
  Future<Map<String, Object?>?> getDailyLogByText(String text) async {
    final db = await database;
    final rows = await db.query(
      'daily_logs',
      where: 'text = ?',
      whereArgs: [text],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  /// Returns the most recent distinct raw texts (for autocomplete suggestions).
  Future<List<String>> getAllDailyLogTexts() async {
    final db = await database;
    final rows = await db.query(
      'daily_logs',
      columns: ['text'],
      distinct: true,
      orderBy: 'id DESC',
      limit: 50,
    );
    return rows.map((row) => row['text'] as String).toList();
  }

  Future<void> deleteRoutine(int id) async {
    final db = await database;
    await db.delete('routines', where: 'id = ?', whereArgs: [id]);
  }

  /// Returns the daily entry row for [date], or `null` when none is saved.
  Future<Map<String, Object?>?> getDailyEntry(String date) async {
    final db = await database;
    final rows = await db.query(
      'daily_entries',
      where: 'date = ?',
      whereArgs: [date],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  /// Returns every daily entry row ordered by date.
  Future<List<Map<String, Object?>>> getAllDailyEntries() async {
    final db = await database;
    return db.query('daily_entries', orderBy: 'date');
  }

  /// Upserts the daily entry for [entry.date] (one row per date).
  Future<void> upsertDailyEntry(DailyEntry entry) async {
    final db = await database;
    await db.insert(
      'daily_entries',
      entry.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Removes the daily entry row for [date], if any.
  Future<void> deleteDailyEntry(String date) async {
    final db = await database;
    await db.delete('daily_entries', where: 'date = ?', whereArgs: [date]);
  }

  /// Returns every symptom reading logged for [date].
  Future<List<Map<String, Object?>>> getSymptomLogs(String date) async {
    final db = await database;
    return db.query(
      'symptom_logs',
      where: 'date = ?',
      whereArgs: [date],
      orderBy: 'id',
    );
  }

  /// Returns every stored symptom reading.
  Future<List<Map<String, Object?>>> getAllSymptomLogs() async {
    final db = await database;
    return db.query('symptom_logs', orderBy: 'date, id');
  }

  /// Upserts one symptom reading for its `(date, symptom)` pair.
  Future<void> upsertSymptomLog(SymptomLog log) async {
    final db = await database;
    await db.insert(
      'symptom_logs',
      log.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Returns the raw value stored for [key] in `app_settings`, or `null`.
  Future<String?> getSetting(String key) async {
    final db = await database;
    final rows = await db.query(
      'app_settings',
      where: 'setting_key = ?',
      whereArgs: [key],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first['setting_value'] as String?;
  }

  /// Upserts the raw [value] for [key] in `app_settings`.
  Future<void> upsertSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'app_settings',
      {'setting_key': key, 'setting_value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Inserts a technical failure record into the local forensics log.
  Future<void> insertErrorLog(ErrorLogEntry entry) async {
    final db = await database;
    await db.insert('local_error_logs', entry.toMap());
  }

  /// Returns local error records newest first.
  Future<List<ErrorLogEntry>> getErrorLogs() async {
    final db = await database;
    final rows = await db.query(
      'local_error_logs',
      orderBy: 'timestamp DESC, id DESC',
    );
    return rows.map(ErrorLogEntry.fromMap).toList(growable: false);
  }

  /// Saves a report and all of its suggested menus atomically.
  Future<int> insertAiDiagnosis(AiDiagnosisReport report) async {
    final db = await database;
    return db.transaction((txn) async {
      final diagnosisId = await txn.insert('ai_diagnoses', {
        'created_at': report.createdAt.toUtc().toIso8601String(),
        'title': report.title,
        'summary': report.summary,
        'considerations_json': jsonEncode(report.considerations),
        'condition_ids_json': jsonEncode(report.conditionIds),
        'food_preferences': report.foodPreferences,
        'language': report.language,
        'response_json': report.responseJson,
      });
      for (final menu in report.menus) {
        await txn.insert('ai_suggested_menus', {
          'diagnosis_id': diagnosisId,
          'name': menu.name,
          'day': menu.day,
          'meals_json': jsonEncode(
            menu.meals.map((meal) => meal.toJson()).toList(),
          ),
        });
      }
      return diagnosisId;
    });
  }

  /// Returns saved diagnosis rows newest first.
  Future<List<Map<String, Object?>>> getAiDiagnoses() async {
    final db = await database;
    return db.query('ai_diagnoses', orderBy: 'created_at DESC, id DESC');
  }

  /// Returns the suggested menus associated with [diagnosisId].
  Future<List<Map<String, Object?>>> getAiSuggestedMenus(
    int diagnosisId,
  ) async {
    final db = await database;
    return db.query(
      'ai_suggested_menus',
      where: 'diagnosis_id = ?',
      whereArgs: [diagnosisId],
      orderBy: 'id',
    );
  }

  /// Returns the single tamagotchi progress row, or `null` when none is saved.
  Future<Map<String, Object?>?> getTamagotchiProgress() async {
    final db = await database;
    final rows = await db.query(
      'tamagotchi_progress',
      where: 'id = 1',
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  /// Computes the current streak: consecutive days (ending today, or yesterday
  /// when today is still inactive) in which at least one exercise or one
  /// healthy meal was logged.
  Future<int> currentStreak() async {
    final db = await database;
    final rows = await db.query(
      'daily_entries',
      columns: ['date', 'exercises_json', 'healthy_meals'],
    );
    final active = <String>{};
    for (final row in rows) {
      final exercisesRaw = row['exercises_json'] as String?;
      final hasExercises =
          exercisesRaw != null && exercisesRaw.isNotEmpty && exercisesRaw != '[]';
      final healthyMeals = (row['healthy_meals'] as int?) ?? 0;
      if (hasExercises || healthyMeals > 0) {
        active.add(row['date'] as String);
      }
    }

    final now = DateTime.now();
    var cursor = DateTime(now.year, now.month, now.day);
    if (!active.contains(DailyEntry.dateKey(cursor))) {
      // M36 Task 1: step by calendar day (immune to DST 23/25-hour days),
      // never by fixed 24-hour durations which can shift the wall date.
      cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
    }
    var streak = 0;
    while (active.contains(DailyEntry.dateKey(cursor))) {
      streak++;
      cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
    }
    return streak;
  }

  /// Upserts the single tamagotchi progress row.
  Future<void> upsertTamagotchiProgress(TamagotchiProgress progress) async {
    final db = await database;
    await db.insert(
      'tamagotchi_progress',
      progress.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Persists a meal quick-logged from a notification action.
  Future<void> insertMealAction(MealAction action) async {
    final db = await database;
    await db.insert('meal_actions', action.toMap());
  }

  /// Returns every meal logged for [date], newest first.
  Future<List<Map<String, Object?>>> getMealActionsByDate(String date) async {
    final db = await database;
    return db.query(
      'meal_actions',
      where: 'date = ?',
      whereArgs: [date],
      orderBy: 'id DESC',
    );
  }

  /// Returns every logged meal, newest first.
  Future<List<Map<String, Object?>>> getAllMealActions() async {
    final db = await database;
    return db.query('meal_actions', orderBy: 'id DESC');
  }

  Future<void> deleteDiet(int id) async {
    final db = await database;
    await db.delete('diets', where: 'id = ?', whereArgs: [id]);
  }

  /// Returns the single profile row, or `null` when none has been saved.
  Future<Map<String, Object?>?> getProfile() async {
    final db = await database;
    final rows = await db.query('profile', where: 'id = 1', limit: 1);
    return rows.isEmpty ? null : rows.first;
  }

  /// Upserts the single profile row.
  Future<void> upsertProfile(UserProfile profile) async {
    final db = await database;
    await db.insert(
      'profile',
      profile.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Returns the single projection plan row, or `null` when none is saved.
  Future<Map<String, Object?>?> getProjectionPlan() async {
    final db = await database;
    final rows = await db.query('projection_plan', where: 'id = 1', limit: 1);
    return rows.isEmpty ? null : rows.first;
  }

  /// Returns all projection milestone rows ordered by month.
  Future<List<Map<String, Object?>>> getProjectionMilestones() async {
    final db = await database;
    return db.query('projection_milestone', orderBy: 'month');
  }

  /// Replaces the stored projection plan and its milestones in a transaction.
  Future<void> saveProjectionPlan(ProjectionPlan plan) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.insert(
        'projection_plan',
        {
          'id': 1,
          'start_weight_kg': plan.startWeightKg,
          'goal': plan.goal.name,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await txn.delete('projection_milestone');
      for (final milestone in plan.milestones) {
        await txn.insert('projection_milestone', milestone.toMap(planId: 1));
      }
    });
  }

  /// Returns every food-log row for [date], oldest first.
  Future<List<Map<String, Object?>>> getFoodLogsByDate(String date) async {
    final db = await database;
    return db.query(
      'food_logs',
      where: 'date = ?',
      whereArgs: [date],
      orderBy: 'id',
    );
  }

  /// Replaces every food-log row for [date] in a single transaction.
  Future<void> replaceFoodLogsByDate(
    String date,
    List<Map<String, Object?>> rows,
  ) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('food_logs', where: 'date = ?', whereArgs: [date]);
      for (final row in rows) {
        await txn.insert('food_logs', row);
      }
    });
  }

  /// Returns every completed-exercise row for [date], oldest first.
  Future<List<Map<String, Object?>>> getExerciseCompletionsByDate(
    String date,
  ) async {
    final db = await database;
    return db.query(
      'exercise_completions',
      where: 'date = ?',
      whereArgs: [date],
      orderBy: 'id',
    );
  }

  /// Replaces every completed-exercise row for [date] in a single transaction.
  Future<void> replaceExerciseCompletionsByDate(
    String date,
    List<Map<String, Object?>> rows,
  ) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(
        'exercise_completions',
        where: 'date = ?',
        whereArgs: [date],
      );
      for (final row in rows) {
        await txn.insert('exercise_completions', row);
      }
    });
  }
}
