import 'dart:convert';

import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/daily_entry.dart';
import '../models/daily_log.dart';
import '../models/diet_models.dart';
import '../models/meal_action.dart';
import '../models/projection_models.dart';
import '../models/routine_models.dart';
import '../models/tamagotchi_progress.dart';
import '../models/user_profile.dart';

/// Local SQLite storage for offline-first persistence of routines and diets.
///
/// A [database] override can be provided (e.g. an in-memory database in tests).
class DatabaseHelper {
  DatabaseHelper({Database? database}) : _databaseOverride = database;

  static const String _dbName = 'nutri_exercise.db';
  static const int _dbVersion = 8;

  final Database? _databaseOverride;
  Database? _database;

  Future<Database> get database async {
    final override = _databaseOverride;
    if (override != null) return override;
    final existing = _database;
    if (existing != null) return existing;
    final dir = await getApplicationDocumentsDirectory();
    _database = await openDatabase(
      '${dir.path}/$_dbName',
      version: _dbVersion,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    return _database!;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE routines (
        id INTEGER PRIMARY KEY,
        weekday TEXT NOT NULL,
        focus TEXT NOT NULL,
        exercises_json TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE diets (
        id INTEGER PRIMARY KEY,
        date TEXT NOT NULL,
        total_calories INTEGER NOT NULL,
        meals_json TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE notification_prefs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        pref_key TEXT NOT NULL UNIQUE,
        enabled INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE profile (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        name TEXT NOT NULL,
        age INTEGER NOT NULL,
        weight_kg REAL NOT NULL,
        height_cm REAL NOT NULL,
        goal TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE daily_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL UNIQUE,
        text TEXT NOT NULL,
        parsed_json TEXT
      )
    ''');
    await _createProjectionTables(db);
    await _createDailyEntryTable(db);
    await _createNotificationHistoryTables(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createProjectionTables(db);
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE daily_logs (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          date TEXT NOT NULL UNIQUE,
          text TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 4) {
      await db.execute(
        'ALTER TABLE daily_logs ADD COLUMN parsed_json TEXT',
      );
    }
    if (oldVersion < 5) {
      await _createDailyEntryTable(db);
    }
    if (oldVersion < 6) {
      await _createNotificationHistoryTables(db);
    }
    if (oldVersion < 7) {
      await db.execute(
        'ALTER TABLE daily_entries ADD COLUMN healthy_meals '
        'INTEGER NOT NULL DEFAULT 0',
      );
    }
    if (oldVersion < 8) {
      await db.execute(
        'ALTER TABLE daily_entries ADD COLUMN burned '
        'INTEGER NOT NULL DEFAULT 0',
      );
    }
  }

  Future<void> _createNotificationHistoryTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS tamagotchi_progress (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        core_fullness REAL NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS meal_actions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        meal TEXT NOT NULL,
        time_of_day TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createDailyEntryTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS daily_entries (
        date TEXT PRIMARY KEY,
        calories INTEGER NOT NULL,
        protein INTEGER NOT NULL,
        carbs INTEGER NOT NULL,
        fat INTEGER NOT NULL,
        exercises_json TEXT NOT NULL,
        healthy_meals INTEGER NOT NULL DEFAULT 0,
        burned INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<void> _createProjectionTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS projection_plan (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        start_weight_kg REAL NOT NULL,
        goal TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS projection_milestone (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        plan_id INTEGER NOT NULL,
        month INTEGER NOT NULL,
        weight_kg REAL NOT NULL,
        shoulder_factor REAL NOT NULL,
        waist_factor REAL NOT NULL,
        focus TEXT NOT NULL
      )
    ''');
  }

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
      cursor = cursor.subtract(const Duration(days: 1));
    }
    var streak = 0;
    while (active.contains(DailyEntry.dateKey(cursor))) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
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
}
