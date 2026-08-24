import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/data/local_profile_repository.dart';
import 'package:nutri_mobile_app/core/database/database_helper.dart';
import 'package:nutri_mobile_app/core/models/user_profile.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
  });

  late DatabaseHelper helper;

  setUp(() async {
    final db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: (db, version) async {
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
        },
      ),
    );
    helper = DatabaseHelper(database: db);
  });

  group('LocalProfileRepository (SQLite)', () {
    test('returns null when no profile row exists', () async {
      final repo = LocalProfileRepository(databaseHelper: helper);

      expect(await repo.getProfile(), isNull);
    });

    test('persists a profile and reads it back', () async {
      final repo = LocalProfileRepository(databaseHelper: helper);

      const profile = UserProfile(
        name: 'Jane Doe',
        age: 28,
        weightKg: 65.5,
        heightCm: 170,
        goal: FitnessGoal.fatLoss,
      );
      await repo.saveProfile(profile);

      final restored = await repo.getProfile();
      expect(restored?.name, 'Jane Doe');
      expect(restored?.age, 28);
      expect(restored?.weightKg, 65.5);
      expect(restored?.heightCm, 170);
      expect(restored?.goal, FitnessGoal.fatLoss);
    });

    test('upsert overwrites the previous profile keeping a single row', () async {
      final repo = LocalProfileRepository(databaseHelper: helper);

      await repo.saveProfile(
        const UserProfile(
          name: 'First',
          age: 20,
          weightKg: 60,
          heightCm: 160,
          goal: FitnessGoal.muscleGain,
        ),
      );
      await repo.saveProfile(
        const UserProfile(
          name: 'Second',
          age: 30,
          weightKg: 80,
          heightCm: 180,
          goal: FitnessGoal.endurance,
        ),
      );

      final restored = await repo.getProfile();
      expect(restored?.name, 'Second');
      expect(restored?.goal, FitnessGoal.endurance);
    });
  });
}