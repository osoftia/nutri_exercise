import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/database/database_schema.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  test('v13 upgrade creates diagnosis and suggested-menu tables', () async {
    final db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(version: 13),
    );
    addTearDown(db.close);

    await DatabaseSchema.upgrade(db, 13, DatabaseSchema.version);

    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table'",
    );
    final names = tables.map((row) => row['name']).toSet();
    expect(names, contains('ai_diagnoses'));
    expect(names, contains('ai_suggested_menus'));
  });

  test('v17 upgrade adds response_json without losing cached reports',
      () async {
    final db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(version: 17),
    );
    addTearDown(db.close);
    await db.execute('''
      CREATE TABLE ai_diagnoses (
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
    await db.insert('ai_diagnoses', {
      'created_at': DateTime.utc(2026, 10, 6).toIso8601String(),
      'title': 'Saved report',
      'summary': 'Existing summary',
      'considerations_json': '[]',
      'condition_ids_json': '["diabetes"]',
      'food_preferences': 'vegetarian',
      'language': 'es',
    });
    await _createVersion18ErrorLogTable(db);

    await DatabaseSchema.upgrade(db, 17, DatabaseSchema.version);

    final columns = await db.rawQuery('PRAGMA table_info(ai_diagnoses)');
    expect(columns.map((column) => column['name']), contains('response_json'));
    final rows = await db.query('ai_diagnoses');
    expect(rows.single['title'], 'Saved report');
    expect(rows.single['response_json'], '');
  });
}

Future<void> _createVersion18ErrorLogTable(Database db) => db.execute('''
  CREATE TABLE local_error_logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    timestamp TEXT NOT NULL,
    error_code TEXT NOT NULL,
    message TEXT NOT NULL,
    stack_trace TEXT NOT NULL,
    request_url TEXT NOT NULL DEFAULT '',
    request_body TEXT NOT NULL DEFAULT ''
  )
''');
