import 'dart:convert';

import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/daily_log.dart';
import '../models/diet_models.dart';
import '../models/projection_models.dart';
import '../models/routine_models.dart';
import '../models/user_profile.dart';

/// Local SQLite storage for offline-first persistence of routines and diets.
///
/// A [database] override can be provided (e.g. an in-memory database in tests).
class DatabaseHelper {
  DatabaseHelper({Database? database}) : _databaseOverride = database;

  static const String _dbName = 'nutri_exercise.db';
  static const int _dbVersion = 3;

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
        text TEXT NOT NULL
      )
    ''');
    await _createProjectionTables(db);
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

  /// Upserts the daily summary for [log.date] (one row per date).
  Future<void> upsertDailyLog(DailyLog log) async {
    final db = await database;
    await db.insert(
      'daily_logs',
      {'date': log.date, 'text': log.text},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteRoutine(int id) async {
    final db = await database;
    await db.delete('routines', where: 'id = ?', whereArgs: [id]);
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
