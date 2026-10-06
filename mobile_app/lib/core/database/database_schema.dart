import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

/// Owns every `CREATE TABLE` / migration statement for the offline store.
///
/// [DatabaseHelper] delegates `onCreate` / `onUpgrade` here so the helper stays
/// focused on the query surface. The class is state-free and every method takes
/// the [Database] explicitly, which keeps the upgrade paths independently
/// testable.
class DatabaseSchema {
  DatabaseSchema._();

  /// Current schema version (bump on every structural change).
  static const int version = 15;

  /// The database file name.
  static const String fileName = 'nutri_exercise.db';

  /// Creates every table on a fresh database.
  static Future<void> createAll(Database db, int version) async {
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
    await createProjectionTables(db);
    await createDailyEntryTable(db);
    await createNotificationHistoryTables(db);
    await createBodyDetailTables(db);
    await createSettingsTable(db);
    await createSymptomTable(db);
    await createAiDiagnosisTables(db);
    await createLocalErrorLogTable(db);
  }

  /// Applies every migration needed to reach the current schema version.
  static Future<void> upgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await createProjectionTables(db);
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
      await createDailyEntryTable(db);
    }
    if (oldVersion < 6) {
      await createNotificationHistoryTables(db);
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
    if (oldVersion < 9) {
      await createBodyDetailTables(db);
    }
    if (oldVersion < 10) {
      await ensureTamagotchiMassColumn(db);
    }
    if (oldVersion < 11) {
      await createSettingsTable(db);
    }
    if (oldVersion < 12) {
      await createSymptomTable(db);
    }
    if (oldVersion < 13) {
      await ensureClinicalNutrientsColumn(db);
    }
    if (oldVersion < 14) {
      await createAiDiagnosisTables(db);
    }
    if (oldVersion < 15) {
      await createLocalErrorLogTable(db);
    }
  }

  /// Creates the local technical error history table (version 15).
  static Future<void> createLocalErrorLogTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS local_error_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp TEXT NOT NULL,
        error_code TEXT NOT NULL,
        message TEXT NOT NULL,
        stack_trace TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_local_error_logs_timestamp
      ON local_error_logs(timestamp DESC, id DESC)
    ''');
  }

  /// Creates local tables for generated clinical reports and their menus.
  static Future<void> createAiDiagnosisTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ai_diagnoses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        created_at TEXT NOT NULL,
        title TEXT NOT NULL,
        summary TEXT NOT NULL,
        considerations_json TEXT NOT NULL,
        condition_ids_json TEXT NOT NULL,
        food_preferences TEXT NOT NULL,
        language TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ai_suggested_menus (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        diagnosis_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        day TEXT NOT NULL,
        meals_json TEXT NOT NULL,
        FOREIGN KEY (diagnosis_id) REFERENCES ai_diagnoses(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_ai_suggested_menus_diagnosis
      ON ai_suggested_menus(diagnosis_id)
    ''');
  }

  /// Creates the `symptom_logs` table (version 12): one severity row per date
  /// and symptom kind.
  static Future<void> createSymptomTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS symptom_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        symptom TEXT NOT NULL,
        level INTEGER NOT NULL,
        UNIQUE(date, symptom)
      )
    ''');
  }

  /// Creates the generic key/value `app_settings` table (version 11).
  static Future<void> createSettingsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_settings (
        setting_key TEXT PRIMARY KEY,
        setting_value TEXT NOT NULL
      )
    ''');
  }

  /// Adds the `mass_json` column to `tamagotchi_progress` (version 10).
  ///
  /// Exposed for tests so the legacy-schema upgrade path can be exercised
  /// without spinning up the real documents-directory database.
  @visibleForTesting
  static Future<void> ensureTamagotchiMassColumn(Database db) async {
    final columns = await db.rawQuery(
      'PRAGMA table_info(tamagotchi_progress)',
    );
    final hasColumn = columns.any((row) => row['name'] == 'mass_json');
    if (hasColumn) return;
    await db.execute(
      "ALTER TABLE tamagotchi_progress ADD COLUMN mass_json TEXT NOT NULL "
      "DEFAULT '{}'",
    );
  }

  /// Creates the durable body-detail `food_logs` / `exercise_completions`
  /// tables (version 9).
  static Future<void> createBodyDetailTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS food_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        name TEXT NOT NULL,
        portion TEXT NOT NULL,
        calories INTEGER NOT NULL,
        protein INTEGER NOT NULL,
        carbs INTEGER NOT NULL,
        fat INTEGER NOT NULL,
        clinical_nutrients_json TEXT,
        time TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS exercise_completions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        name TEXT NOT NULL,
        planned_sets INTEGER NOT NULL,
        completed_sets INTEGER NOT NULL,
        reps INTEGER NOT NULL,
        load_kg REAL NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
  }

  /// Adds optional clinical nutrient metadata to legacy `food_logs` tables.
  ///
  /// The column check matters when upgrading from a version before the body
  /// detail tables existed: their creation already uses the current shape.
  @visibleForTesting
  static Future<void> ensureClinicalNutrientsColumn(Database db) async {
    final columns = await db.rawQuery('PRAGMA table_info(food_logs)');
    if (columns.any((row) => row['name'] == 'clinical_nutrients_json')) return;
    await db.execute(
      'ALTER TABLE food_logs ADD COLUMN clinical_nutrients_json TEXT',
    );
  }

  /// Creates the `tamagotchi_progress` / `meal_actions` tables (version 6).
  static Future<void> createNotificationHistoryTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS tamagotchi_progress (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        core_fullness REAL NOT NULL,
        mass_json TEXT NOT NULL DEFAULT '{}',
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

  /// Creates the `daily_entries` calendar table (version 5).
  static Future<void> createDailyEntryTable(Database db) async {
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

  /// Creates the long-term projection tables (version 2).
  static Future<void> createProjectionTables(Database db) async {
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
}
