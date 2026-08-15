import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/diet_models.dart';
import '../models/routine_models.dart';

/// Local SQLite storage for offline-first persistence of routines and diets.
///
/// A [database] override can be provided (e.g. an in-memory database in tests).
class DatabaseHelper {
  DatabaseHelper({Database? database}) : _databaseOverride = database;

  static const String _dbName = 'nutri_exercise.db';
  static const int _dbVersion = 2;

  final Database? _databaseOverride;
  Database? _database;

  Future<Database> get database async {
    final override = _databaseOverride;
    if (override != null) return override;
    final existing = _database;
    if (existing != null) return existing;
    final dbPath = p.join(await getDatabasesPath(), _dbName);
    _database = await openDatabase(
      dbPath,
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
        created_at TEXT,
        is_generated INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE exercises (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        routine_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        muscle_group TEXT NOT NULL,
        sets INTEGER NOT NULL,
        reps TEXT NOT NULL,
        rest_seconds INTEGER NOT NULL,
        weight TEXT,
        position INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (routine_id) REFERENCES routines (id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE sets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        exercise_id INTEGER NOT NULL,
        set_number INTEGER NOT NULL,
        reps INTEGER NOT NULL,
        weight TEXT,
        is_completed INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (exercise_id) REFERENCES exercises (id) ON DELETE CASCADE
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

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE routines_v2 (
          id INTEGER PRIMARY KEY,
          weekday TEXT NOT NULL,
          focus TEXT NOT NULL,
          created_at TEXT,
          is_generated INTEGER NOT NULL DEFAULT 0
        )
      ''');
      await db.execute('''
        CREATE TABLE exercises (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          routine_id INTEGER NOT NULL,
          name TEXT NOT NULL,
          muscle_group TEXT NOT NULL,
          sets INTEGER NOT NULL,
          reps TEXT NOT NULL,
          rest_seconds INTEGER NOT NULL,
          weight TEXT,
          position INTEGER NOT NULL DEFAULT 0,
          FOREIGN KEY (routine_id) REFERENCES routines_v2 (id) ON DELETE CASCADE
        )
      ''');
      await db.execute('''
        CREATE TABLE sets (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          exercise_id INTEGER NOT NULL,
          set_number INTEGER NOT NULL,
          reps INTEGER NOT NULL,
          weight TEXT,
          is_completed INTEGER NOT NULL DEFAULT 0,
          FOREIGN KEY (exercise_id) REFERENCES exercises (id) ON DELETE CASCADE
        )
      ''');

      final oldRows = await db.query('routines');
      for (final row in oldRows) {
        final id = row['id'] as int;
        final weekday = row['weekday'] as String;
        final focus = row['focus'] as String;
        final exercisesJson = row['exercises_json'] as String? ?? '[]';
        final exercises = (jsonDecode(exercisesJson) as List<dynamic>)
            .map((e) => Exercise.fromJson(e as Map<String, dynamic>))
            .toList();

        await db.insert('routines_v2', {
          'id': id,
          'weekday': weekday,
          'focus': focus,
          'created_at': DateTime.now().toIso8601String(),
          'is_generated': 0,
        });
        for (var i = 0; i < exercises.length; i++) {
          final ex = exercises[i];
          final exId = await db.insert('exercises', {
            'routine_id': id,
            'name': ex.name,
            'muscle_group': ex.muscleGroup,
            'sets': ex.sets,
            'reps': ex.reps,
            'rest_seconds': ex.restSeconds,
            'weight': ex.weight,
            'position': i,
          });
          for (var s = 1; s <= ex.sets; s++) {
            await db.insert('sets', {
              'exercise_id': exId,
              'set_number': s,
              'reps': _parseReps(ex.reps),
              'weight': ex.weight,
              'is_completed': 0,
            });
          }
        }
      }

      await db.execute('DROP TABLE routines');
      await db.execute('ALTER TABLE routines_v2 RENAME TO routines');
    }
  }

  Future<List<Map<String, Object?>>> getRoutines() async {
    final db = await database;
    return db.query('routines', orderBy: 'id');
  }

  Future<Map<String, Object?>?> getRoutineById(int id) async {
    final db = await database;
    final rows = await db.query('routines', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : rows.first;
  }

  Future<int> insertRoutine({
    required int id,
    required String weekday,
    required String focus,
    bool isGenerated = false,
  }) async {
    final db = await database;
    return db.insert('routines', {
      'id': id,
      'weekday': weekday,
      'focus': focus,
      'created_at': DateTime.now().toIso8601String(),
      'is_generated': isGenerated ? 1 : 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteRoutine(int id) async {
    final db = await database;
    await db.delete('routines', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, Object?>>> getExercisesForRoutine(int routineId) async {
    final db = await database;
    return db.query('exercises',
        where: 'routine_id = ?', whereArgs: [routineId], orderBy: 'position');
  }

  Future<int> insertExercise({
    required int routineId,
    required Exercise exercise,
    required int position,
  }) async {
    final db = await database;
    return db.insert('exercises', {
      'routine_id': routineId,
      'name': exercise.name,
      'muscle_group': exercise.muscleGroup,
      'sets': exercise.sets,
      'reps': exercise.reps,
      'rest_seconds': exercise.restSeconds,
      'weight': exercise.weight,
      'position': position,
    });
  }

  Future<List<Map<String, Object?>>> getSetsForExercise(int exerciseId) async {
    final db = await database;
    return db.query('sets',
        where: 'exercise_id = ?', whereArgs: [exerciseId], orderBy: 'set_number');
  }

  Future<int> insertSet({
    required int exerciseId,
    required int setNumber,
    required int reps,
    String? weight,
  }) async {
    final db = await database;
    return db.insert('sets', {
      'exercise_id': exerciseId,
      'set_number': setNumber,
      'reps': reps,
      'weight': weight,
      'is_completed': 0,
    });
  }

  Future<List<Map<String, Object?>>> getDiets() async {
    final db = await database;
    return db.query('diets', orderBy: 'id');
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

  Future<void> clearAll() async {
    final db = await database;
    await db.delete('sets');
    await db.delete('exercises');
    await db.delete('routines');
    await db.delete('diets');
  }

  /// Persists a full [WorkoutDay] (routine + exercises + sets) atomically.
  Future<void> saveWorkoutDay(WorkoutDay day, {bool isGenerated = false}) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.insert('routines', {
        'id': day.id,
        'weekday': day.weekday,
        'focus': day.focus,
        'created_at': DateTime.now().toIso8601String(),
        'is_generated': isGenerated ? 1 : 0,
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      await txn.delete('exercises', where: 'routine_id = ?', whereArgs: [day.id]);

      for (var i = 0; i < day.exercises.length; i++) {
        final ex = day.exercises[i];
        final exId = await txn.insert('exercises', {
          'routine_id': day.id,
          'name': ex.name,
          'muscle_group': ex.muscleGroup,
          'sets': ex.sets,
          'reps': ex.reps,
          'rest_seconds': ex.restSeconds,
          'weight': ex.weight,
          'position': i,
        });
        for (var s = 1; s <= ex.sets; s++) {
          await txn.insert('sets', {
            'exercise_id': exId,
            'set_number': s,
            'reps': _parseReps(ex.reps),
            'weight': ex.weight,
            'is_completed': 0,
          });
        }
      }
    });
  }

  int _parseReps(String reps) {
    final match = RegExp(r'\d+').firstMatch(reps);
    return match == null ? 10 : int.parse(match.group(0)!);
  }
}