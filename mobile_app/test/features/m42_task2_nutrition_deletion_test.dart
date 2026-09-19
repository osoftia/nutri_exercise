import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/data/body_detail_repository.dart';
import 'package:nutri_mobile_app/core/domain/body_projection/body_segment.dart';
import 'package:nutri_mobile_app/core/domain/body_projection/muscle_workout_log.dart';
import 'package:nutri_mobile_app/core/domain/body_projection/nutrition_log.dart';
import 'package:nutri_mobile_app/core/domain/popups/exercise_completion.dart';
import 'package:nutri_mobile_app/core/services/rule_based_muscle_gap_advisor.dart';
import 'package:nutri_mobile_app/core/state/body_detail_controller.dart';
import 'package:nutri_mobile_app/core/state/muscle_tamagotchi_state.dart';

class _RecordingRepository implements BodyDetailRepository {
  DailyFoodLog foodLog = const DailyFoodLog();
  final List<DailyFoodLog> savedFoodLogs = [];

  @override
  Future<DailyFoodLog> loadTodayFoodLog() async => foodLog;

  @override
  Future<void> saveTodayFoodLog(DailyFoodLog log) async {
    foodLog = log;
    savedFoodLogs.add(log);
  }

  @override
  Future<MuscleWorkoutLog> loadWorkoutLog(BodySegment segment) async =>
      MuscleWorkoutLog(segment: segment, periodLabel: 'This week');

  @override
  Future<List<CompletedExercise>> loadCompletedExercises() async => const [];

  @override
  Future<void> saveCompletedExercises(List<CompletedExercise> exercises) async {}
}

const _startingLog = DailyFoodLog(
  entries: [
    LoggedFood(name: 'Oatmeal', portion: '1 bowl', calories: 420, time: '08:10'),
    LoggedFood(name: 'Chicken', portion: '200 g', calories: 650, time: '13:20'),
    LoggedFood(name: 'Yogurt', portion: '150 g', calories: 240, time: '17:00'),
  ],
);

void main() {
  group('M42 nutrition deletion-only flow', () {
    test('removing food persists the reduced log and slims the abdomen', () async {
      final repository = _RecordingRepository()..foodLog = _startingLog;
      final tamagotchi = MuscleTamagotchiState()..applyNutrition(1000);
      final controller = BodyDetailController(
        repository: repository,
        advisor: const RuleBasedMuscleGapAdvisor(),
        tamagotchi: tamagotchi,
      );
      await controller.loadFoodLog();
      final before = controller.buildViewModel().scaleFor(BodySegment.abdomen);

      await controller.removeFood(1);

      expect(repository.savedFoodLogs, hasLength(1));
      expect(
        repository.savedFoodLogs.last.entries.map((entry) => entry.name),
        ['Oatmeal', 'Yogurt'],
      );
      expect(
        controller.buildViewModel().scaleFor(BodySegment.abdomen),
        lessThan(before),
      );
    });

    test('adding still works for the preset/RAG pipeline', () async {
      final repository = _RecordingRepository();
      final controller = BodyDetailController(
        repository: repository,
        advisor: const RuleBasedMuscleGapAdvisor(),
        tamagotchi: MuscleTamagotchiState(),
      );

      await controller.addFood(
        const LoggedFood(
          name: 'Protein Shake',
          portion: '1 scoop',
          calories: 150,
          proteinG: 30,
          time: '18:00',
        ),
      );

      expect(repository.savedFoodLogs, hasLength(1));
      expect(repository.savedFoodLogs.single.entries, hasLength(1));
    });
  });
}
