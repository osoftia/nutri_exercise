import 'dart:convert';

import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/diet_models.dart';
import '../models/routine_models.dart';

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
}
