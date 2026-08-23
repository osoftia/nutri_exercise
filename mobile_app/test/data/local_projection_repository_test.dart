import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/data/local_projection_repository.dart';
import 'package:nutri_mobile_app/core/database/database_helper.dart';
import 'package:nutri_mobile_app/core/models/projection_models.dart';
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
        version: 2,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE projection_plan (
              id INTEGER PRIMARY KEY CHECK (id = 1),
              start_weight_kg REAL NOT NULL,
              goal TEXT NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE projection_milestone (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              plan_id INTEGER NOT NULL,
              month INTEGER NOT NULL,
              weight_kg REAL NOT NULL,
              shoulder_factor REAL NOT NULL,
              waist_factor REAL NOT NULL,
              focus TEXT NOT NULL
            )
          ''');
        },
      ),
    );
    helper = DatabaseHelper(database: db);
  });

  group('LocalProjectionRepository (SQLite)', () {
    test('seeds a generated plan when none exists', () async {
      final repo = LocalProjectionRepository(
        databaseHelper: helper,
        startWeightKg: 70,
        goal: FitnessGoal.muscleGain,
      );

      final plan = await repo.loadPlan();

      expect(plan.milestones.map((m) => m.month), [0, 1, 3, 6]);
      expect(plan.milestoneFor(6)!.shoulderFactor, 1.0);
    });

    test('savePlan round-trips milestones with weight and factors', () async {
      final repo = LocalProjectionRepository(databaseHelper: helper);
      final plan = generateProjectionPlan(
        startWeightKg: 80,
        goal: FitnessGoal.fatLoss,
      );
      await repo.savePlan(plan);

      final restored = await repo.loadPlan();

      expect(restored.startWeightKg, 80);
      expect(restored.goal, FitnessGoal.fatLoss);
      expect(restored.milestoneFor(3)!.weightKg, closeTo(76.0, 0.0001));
      expect(restored.milestoneFor(3)!.waistFactor, closeTo(0.34, 0.0001));
      expect(restored.milestoneFor(6)!.waistFactor, closeTo(0.25, 0.0001));
    });
  });
}
