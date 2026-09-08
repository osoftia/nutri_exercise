import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/data/local_daily_entry_repository.dart';
import 'package:nutri_mobile_app/core/database/database_helper.dart';
import 'package:nutri_mobile_app/core/models/daily_entry.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  late DatabaseHelper helper;
  late LocalDailyEntryRepository repository;
  Database? testDb;

  setUp(() async {
    testDb = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 5,
        singleInstance: false,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE daily_entries (
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
        },
      ),
    );
    helper = DatabaseHelper(database: testDb);
    repository = LocalDailyEntryRepository(databaseHelper: helper);
  });

  tearDown(() async {
    await testDb?.close();
  });

  group('LocalDailyEntryRepository', () {
    test('returns null when no entry exists for a date', () async {
      expect(await repository.getByDate('2026-09-03'), isNull);
    });

    test('saves and reads an entry back', () async {
      const entry = DailyEntry(
        date: '2026-09-03',
        calories: 2100,
        protein: 140,
        carbs: 220,
        fat: 70,
        exercises: ['Bench Press', 'Squat'],
      );

      await repository.save(entry);

      final restored = await repository.getByDate('2026-09-03');
      expect(restored, isNotNull);
      expect(restored!.calories, 2100);
      expect(restored.exercises, ['Bench Press', 'Squat']);
    });

    test('upserting the same date replaces the previous values', () async {
      await repository.save(
        const DailyEntry(date: '2026-09-03', calories: 1000),
      );
      await repository.save(
        const DailyEntry(date: '2026-09-03', calories: 2000),
      );

      final restored = await repository.getByDate('2026-09-03');
      expect(restored!.calories, 2000);
    });

    test('lists every stored entry', () async {
      await repository.save(const DailyEntry(date: '2026-09-03', calories: 100));
      await repository.save(const DailyEntry(date: '2026-09-04', calories: 200));

      final all = await repository.getAll();

      expect(all, hasLength(2));
    });

    test('deletes an entry by date', () async {
      await repository.save(const DailyEntry(date: '2026-09-03', calories: 100));

      await repository.delete('2026-09-03');

      expect(await repository.getByDate('2026-09-03'), isNull);
      expect(await repository.getAll(), isEmpty);
    });
  });
}
