import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/database/database_helper.dart';
import 'package:nutri_mobile_app/core/models/diet_models.dart';
import 'package:nutri_mobile_app/core/models/projection_models.dart';
import 'package:nutri_mobile_app/core/models/routine_models.dart';
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

  group('DatabaseHelper routines', () {
    test('upserts and reads routines, then deletes', () async {
      const day = WorkoutDay(
        id: 1,
        weekday: 'Monday',
        focus: 'Push',
        exercises: [
          Exercise(
            id: 1,
            name: 'Bench',
            muscleGroup: 'Chest',
            sets: 4,
            reps: '8-12',
            restSeconds: 90,
          ),
        ],
      );
      await helper.upsertRoutine(day);

      var rows = await helper.getRoutines();
      expect(rows, hasLength(1));
      expect(rows.first['weekday'], 'Monday');

      await helper.deleteRoutine(1);
      rows = await helper.getRoutines();
      expect(rows, isEmpty);
    });
  });

  group('DatabaseHelper diets', () {
    test('upserts and reads diets, then deletes', () async {
      const menu = DailyMenu(
        id: 1,
        date: '2026-08-07',
        totalCalories: 2000,
        meals: [
          Meal(
            id: 1,
            name: 'Lunch',
            mealType: MealType.lunch,
            calories: 650,
            protein: 45,
            carbs: 55,
            fat: 18,
          ),
        ],
      );
      await helper.upsertDiet(menu);

      var rows = await helper.getDiets();
      expect(rows, hasLength(1));
      expect(rows.first['total_calories'], 2000);

      await helper.deleteDiet(1);
      rows = await helper.getDiets();
      expect(rows, isEmpty);
    });
  });

  group('DatabaseHelper notification prefs', () {
    test('upserts and reads preferences', () async {
      await helper.upsertNotificationPref('daily_reminder', true);
      await helper.upsertNotificationPref('weekly_digest', false);

      final rows = await helper.getNotificationPrefs();
      expect(rows, hasLength(2));
    });
  });

  group('DatabaseHelper profile', () {
    test('returns null when no profile exists', () async {
      expect(await helper.getProfile(), isNull);
    });

    test('upserts and reads the single profile row', () async {
      const profile = UserProfile(
        name: 'Jane',
        age: 28,
        weightKg: 65.5,
        heightCm: 170,
        goal: FitnessGoal.muscleGain,
      );
      await helper.upsertProfile(profile);

      final row = await helper.getProfile();
      expect(row, isNotNull);
      expect(row!['name'], 'Jane');
      expect(row['goal'], 'muscleGain');
    });
  });

  group('DatabaseHelper projection', () {
    test('saves and reads a projection plan with milestones', () async {
      final plan = generateProjectionPlan(
        startWeightKg: 70,
        goal: FitnessGoal.muscleGain,
      );
      await helper.saveProjectionPlan(plan);

      final planRow = await helper.getProjectionPlan();
      expect(planRow!['start_weight_kg'], 70.0);

      final milestones = await helper.getProjectionMilestones();
      expect(milestones, hasLength(4));
      expect(milestones.first['month'], 0);
    });
  });
}
