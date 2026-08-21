import 'dart:convert';

import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/diet_models.dart';
import '../models/routine_models.dart';
import '../models/user_profile.dart';

/// Local SQLite storage for offline-first persistence of routines and diets.
///
/// A [database] override can be provided (e.g. an in-memory database in tests).
class DatabaseHelper {
  DatabaseHelper({Database? database}) : _databaseOverride = database;

  static const String _dbName = 'nutri_exercise.db';
  static const int _dbVersion = 1;

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
  }

  Future<List<Map<String, Object?>>> getRoutines() async {
    final db = await database;
    return db.query('routines', orderBy: 'id');
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
}
