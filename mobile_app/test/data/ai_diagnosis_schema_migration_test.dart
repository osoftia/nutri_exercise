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
}
