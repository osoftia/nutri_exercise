import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/data/local_body_detail_repository.dart';
import 'package:nutri_mobile_app/core/database/database_helper.dart';
import 'package:nutri_mobile_app/core/domain/body_projection/body_segment.dart';
import 'package:nutri_mobile_app/core/domain/body_projection/nutrition_log.dart';
import 'package:nutri_mobile_app/core/domain/popups/exercise_completion.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const _date = '2026-09-18';

const _foods = DailyFoodLog(
  entries: [
    LoggedFood(
      name: 'Oatmeal',
      portion: '1 bowl',
      calories: 420,
      proteinG: 12,
      carbsG: 60,
      fatG: 12,
      saturatedFatG: 1.2,
      sugarsG: 7,
      fiberG: 8,
      glycemicIndex: 55,
      purinesMg: 15,
      sodiumMg: 10,
      time: '08:10',
    ),
    LoggedFood(
      name: 'Chicken',
      portion: '200 g',
      calories: 650,
      proteinG: 45,
      carbsG: 55,
      fatG: 18,
      time: '13:20',
    ),
  ],
);

const _completions = [
  CompletedExercise(
    name: 'Bench Press',
    plannedSets: 4,
    completedSets: 3,
    reps: 8,
    loadKg: 60,
  ),
  CompletedExercise(
    name: 'Squat',
    plannedSets: 4,
    completedSets: 4,
    reps: 10,
    loadKg: 70,
  ),
];

void main() {
  setUpAll(sqfliteFfiInit);

  late DatabaseHelper helper;
  late LocalBodyDetailRepository repository;
  Database? testDb;

  setUp(() async {
    testDb = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 9,
        singleInstance: false,
        onCreate: (db, version) async {
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
              clinical_nutrients_json TEXT,
              time TEXT NOT NULL,
              created_at TEXT NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE exercise_completions (
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
        },
      ),
    );
    helper = DatabaseHelper(database: testDb);
    repository = LocalBodyDetailRepository(
      databaseHelper: helper,
      dateKey: () => _date,
    );
  });

  tearDown(() async {
    await testDb?.close();
  });

  group('LocalBodyDetailRepository', () {
    test('food logs survive a repository restart', () async {
      await repository.saveTodayFoodLog(_foods);

      final restarted = LocalBodyDetailRepository(
        databaseHelper: helper,
        dateKey: () => _date,
      );
      final loaded = await restarted.loadTodayFoodLog();

      expect(loaded.entries, hasLength(2));
      expect(loaded.totalCalories, 1070);
      expect(loaded.entries.first.name, 'Oatmeal');
      expect(loaded.entries.first.saturatedFatG, 1.2);
      expect(loaded.entries.first.fiberG, 8);
    });

    test('saving replaces the previous food log', () async {
      await repository.saveTodayFoodLog(_foods);
      await repository.saveTodayFoodLog(
        _foods.copyWith(entries: _foods.entries.sublist(1)),
      );

      final loaded = await repository.loadTodayFoodLog();
      expect(loaded.entries, hasLength(1));
      expect(loaded.entries.single.name, 'Chicken');
    });

    test('returns an empty log when nothing is stored', () async {
      expect((await repository.loadTodayFoodLog()).isEmpty, isTrue);
    });

    test('completed exercises survive a restart', () async {
      await repository.saveCompletedExercises(_completions);

      final restarted = LocalBodyDetailRepository(
        databaseHelper: helper,
        dateKey: () => _date,
      );
      final loaded = await restarted.loadCompletedExercises();

      expect(loaded, hasLength(2));
      final bench = loaded.firstWhere((e) => e.name == 'Bench Press');
      expect(bench.plannedSets, 4);
      expect(bench.completedSets, 3);
      expect(bench.loadKg, 60);
    });

    test('saving completions replaces the previous records', () async {
      await repository.saveCompletedExercises(_completions);
      await repository.saveCompletedExercises([_completions.first]);

      expect(await repository.loadCompletedExercises(), hasLength(1));
    });

    test('completed exercises overlay the planned workout log', () async {
      await repository.saveCompletedExercises([
        const CompletedExercise(
          name: 'Bench Press',
          plannedSets: 4,
          completedSets: 3,
          reps: 8,
          loadKg: 60,
        ),
      ]);

      final log = await repository.loadWorkoutLog(BodySegment.chest);

      final bench = log.entries.firstWhere((e) => e.name == 'Bench Press');
      expect(bench.plannedSets, 4);
      expect(bench.completedSets, 3);
      expect(log.completedSets, greaterThan(0));
    });
  });
}
