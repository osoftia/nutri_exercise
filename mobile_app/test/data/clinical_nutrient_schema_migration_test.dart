import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/database/database_schema.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  test('adds optional clinical nutrient metadata to existing food logs',
      () async {
    final db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 12,
        singleInstance: false,
        onCreate: (db, _) async {
          await db.execute('''
            CREATE TABLE food_logs (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              date TEXT NOT NULL,
              name TEXT NOT NULL,
              portion TEXT NOT NULL,
              calories INTEGER NOT NULL,
              protein INTEGER NOT NULL,
              carbs INTEGER NOT NULL,
              fat INTEGER NOT NULL,
              time TEXT NOT NULL,
              created_at TEXT NOT NULL
            )
          ''');
        },
        onUpgrade: DatabaseSchema.upgrade,
      ),
    );
    addTearDown(db.close);

    await db.setVersion(13);
    await DatabaseSchema.upgrade(db, 12, 13);
    final columns = await db.rawQuery('PRAGMA table_info(food_logs)');

    expect(
      columns.any((column) => column['name'] == 'clinical_nutrients_json'),
      isTrue,
    );
  });
}
