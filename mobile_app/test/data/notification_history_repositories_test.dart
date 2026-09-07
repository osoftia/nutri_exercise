import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/data/local_meal_action_repository.dart';
import 'package:nutri_mobile_app/core/data/local_tamagotchi_progress_repository.dart';
import 'package:nutri_mobile_app/core/database/database_helper.dart';
import 'package:nutri_mobile_app/core/models/meal_action.dart';
import 'package:nutri_mobile_app/core/models/tamagotchi_progress.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  group('LocalTamagotchiProgressRepository (SQLite)', () {
    late LocalTamagotchiProgressRepository repo;

    setUp(() async {
      final db = await databaseFactoryFfi.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: 1,
          singleInstance: false,
          onCreate: (db, version) async {
            await db.execute('''
              CREATE TABLE tamagotchi_progress (
                id INTEGER PRIMARY KEY CHECK (id = 1),
                core_fullness REAL NOT NULL,
                updated_at TEXT NOT NULL
              )
            ''');
          },
        ),
      );
      repo = LocalTamagotchiProgressRepository(databaseHelper: DatabaseHelper(database: db));
    });

    test('returns null when nothing has been saved', () async {
      expect(await repo.get(), isNull);
    });

    test('persists and reads the progress back', () async {
      await repo.save(const TamagotchiProgress(coreFullness: 0.5));

      final restored = await repo.get();
      expect(restored, isNotNull);
      expect(restored!.coreFullness, 0.5);
    });

    test('save replaces the previous value', () async {
      await repo.save(const TamagotchiProgress(coreFullness: 0.2));
      await repo.save(const TamagotchiProgress(coreFullness: 0.8));

      expect((await repo.get())!.coreFullness, 0.8);
    });
  });

  group('LocalMealActionRepository (SQLite)', () {
    late LocalMealActionRepository repo;

    setUp(() async {
      final db = await databaseFactoryFfi.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: 1,
          singleInstance: false,
          onCreate: (db, version) async {
            await db.execute('''
              CREATE TABLE meal_actions (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                date TEXT NOT NULL,
                meal TEXT NOT NULL,
                time_of_day TEXT NOT NULL,
                created_at TEXT NOT NULL
              )
            ''');
          },
        ),
      );
      repo = LocalMealActionRepository(databaseHelper: DatabaseHelper(database: db));
    });

    test('logs a meal and reads it back by date', () async {
      await repo.logMeal(
        const MealAction(date: '2026-09-03', meal: 'Avena', timeOfDay: 'breakfast'),
      );

      final rows = await repo.getByDate('2026-09-03');
      expect(rows, hasLength(1));
      expect(rows.first.meal, 'Avena');
      expect(rows.first.timeOfDay, 'breakfast');
    });

    test('lists every logged meal', () async {
      await repo.logMeal(
        const MealAction(date: '2026-09-03', meal: 'Avena', timeOfDay: 'breakfast'),
      );
      await repo.logMeal(
        const MealAction(date: '2026-09-03', meal: 'Frutas', timeOfDay: 'breakfast'),
      );

      expect(await repo.getAll(), hasLength(2));
    });
  });
}