import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/data/body_detail_repository.dart';
import 'package:nutri_mobile_app/core/database/database_helper.dart';
import 'package:nutri_mobile_app/core/domain/body_projection/body_segment.dart';
import 'package:nutri_mobile_app/core/domain/body_projection/muscle_workout_log.dart';
import 'package:nutri_mobile_app/core/domain/body_projection/nutrition_log.dart';
import 'package:nutri_mobile_app/core/domain/popups/exercise_completion.dart';
import 'package:nutri_mobile_app/core/mocks/mock_tamagotchi_progress_repository.dart';
import 'package:nutri_mobile_app/core/models/tamagotchi_progress.dart';
import 'package:nutri_mobile_app/core/state/muscle_tamagotchi_state.dart';
import 'package:nutri_mobile_app/core/state/workout_completion_controller.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const _bench = CompletedExercise(
  name: 'Bench Press',
  plannedSets: 4,
  completedSets: 4,
  reps: 8,
  loadKg: 60,
);

class _RecordingRepository implements BodyDetailRepository {
  DailyFoodLog foodLog = const DailyFoodLog();
  List<CompletedExercise> completed = const [];
  int saveCompletionsCalls = 0;

  @override
  Future<DailyFoodLog> loadTodayFoodLog() async => foodLog;

  @override
  Future<void> saveTodayFoodLog(DailyFoodLog log) async => foodLog = log;

  @override
  Future<MuscleWorkoutLog> loadWorkoutLog(BodySegment segment) async =>
      MuscleWorkoutLog(segment: segment, periodLabel: 'This week');

  @override
  Future<List<CompletedExercise>> loadCompletedExercises() async => completed;

  @override
  Future<void> saveCompletedExercises(List<CompletedExercise> exercises) async {
    completed = exercises;
    saveCompletionsCalls++;
  }
}

void main() {
  setUpAll(sqfliteFfiInit);

  group('M42 tamagotchi progress serialization', () {
    test('round-trips per-group mass alongside core fullness', () {
      const progress = TamagotchiProgress(
        coreFullness: 0.42,
        mass: {'chest': 0.9, 'legs': 0.3},
      );

      final restored = TamagotchiProgress.fromMap(progress.toMap());

      expect(restored.coreFullness, 0.42);
      expect(restored.mass['chest'], 0.9);
      expect(restored.mass['legs'], 0.3);
    });

    test('defaults to an empty mass map when the column is absent', () {
      final restored = TamagotchiProgress.fromMap({
        'core_fullness': 0.5,
        'updated_at': '',
      });
      expect(restored.mass, isEmpty);
    });
  });

  group('M42 DatabaseHelper tamagotchi migration', () {
    late Database db;

    setUp(() async {
      db = await databaseFactoryFfi.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: 9,
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
    });

    tearDown(() async {
      await db.close();
    });

    test('upgrades a legacy table with the mass_json column', () async {
      await DatabaseHelper.ensureTamagotchiMassColumn(db);

      final columns = await db.rawQuery('PRAGMA table_info(tamagotchi_progress)');
      expect(
        columns.map((row) => row['name']),
        contains('mass_json'),
      );
    });

    test('persists mass through the upgraded table', () async {
      await DatabaseHelper.ensureTamagotchiMassColumn(db);
      final helper = DatabaseHelper(database: db);

      await helper.upsertTamagotchiProgress(
        const TamagotchiProgress(coreFullness: 0.6, mass: {'arms': 0.75}),
      );
      final row = await helper.getTamagotchiProgress();

      expect(row, isNotNull);
      expect(row!['core_fullness'], 0.6);
      final restored = TamagotchiProgress.fromMap(row);
      expect(restored.mass['arms'], 0.75);
    });
  });

  group('M42 MuscleTamagotchiState persistence', () {
    test('restore hydrates mass and core fullness from SQLite', () async {
      final repository = MockTamagotchiProgressRepository(
        const TamagotchiProgress(
          coreFullness: 0.8,
          mass: {'chest': 0.95, 'arms': 0.15},
        ),
      );
      final state = MuscleTamagotchiState(repository: repository);

      await state.restore();

      expect(state.coreFullness, 0.8);
      expect(state.massOf(MuscleTamagotchiGroup.chest), 0.95);
      expect(state.massOf(MuscleTamagotchiGroup.arms), 0.15);
    });

    test('growth and feeding auto-persist the new state', () async {
      final repository = MockTamagotchiProgressRepository();
      final state = MuscleTamagotchiState(repository: repository);

      state.applyGrowth(const [MuscleTamagotchiGroup.chest]);
      state.applyNutrition(1000);
      await Future<void>.delayed(Duration.zero);

      final saved = await repository.get();
      expect(saved, isNotNull);
      expect(saved!.mass['chest'], greaterThan(0.5));
      expect(saved.coreFullness, greaterThan(0));
    });

    test('slimming and shrinking auto-persist the reverted state', () async {
      final repository = MockTamagotchiProgressRepository(
        const TamagotchiProgress(
          coreFullness: 0.8,
          mass: {'chest': 0.9},
        ),
      );
      final state = MuscleTamagotchiState(repository: repository);
      await state.restore();

      state.applyShrink(const [MuscleTamagotchiGroup.chest]);
      state.applySlimming(amount: 0.3);
      await Future<void>.delayed(Duration.zero);

      final saved = await repository.get();
      expect(saved!.mass['chest'], lessThan(0.9));
      expect(saved.coreFullness, lessThan(0.8));
    });
  });

  group('M42 WorkoutCompletionController hydration', () {
    test('restore reflects persisted completions without re-writing', () async {
      final repository = _RecordingRepository()..completed = const [_bench];
      final controller = WorkoutCompletionController(repository: repository);

      expect(controller.isConfirmed, isFalse);

      await controller.restore();

      expect(controller.isConfirmed, isTrue);
      expect(controller.summary!.caloriesBurned, 250);
      expect(repository.saveCompletionsCalls, 0);
    });

    test('restore stays idle when nothing is persisted', () async {
      final controller =
          WorkoutCompletionController(repository: _RecordingRepository());

      await controller.restore();

      expect(controller.isConfirmed, isFalse);
      expect(controller.summary, isNull);
    });
  });
}
