import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/data/body_detail_repository.dart';
import 'package:nutri_mobile_app/core/domain/body_projection/body_segment.dart';
import 'package:nutri_mobile_app/core/domain/body_projection/muscle_workout_log.dart';
import 'package:nutri_mobile_app/core/domain/body_projection/nutrition_log.dart';
import 'package:nutri_mobile_app/core/domain/popups/exercise_completion.dart';
import 'package:nutri_mobile_app/core/mocks/mock_body_detail_repository.dart';
import 'package:nutri_mobile_app/core/mocks/mock_projection_repository.dart';
import 'package:nutri_mobile_app/core/services/rule_based_muscle_gap_advisor.dart';
import 'package:nutri_mobile_app/core/state/body_detail_controller.dart';
import 'package:nutri_mobile_app/core/state/muscle_tamagotchi_state.dart';
import 'package:nutri_mobile_app/core/state/projection_controller.dart';
import 'package:nutri_mobile_app/core/state/workout_completion_controller.dart';
import 'package:nutri_mobile_app/core/theme/app_theme.dart';
import 'package:nutri_mobile_app/ui/pages/routines_page.dart';

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
  }
}

void main() {
  group('M41 toggleable workout controller', () {
    test('confirming persists, grows the avatar and sets the flag', () async {
      final repository = _RecordingRepository();
      final tamagotchi = MuscleTamagotchiState();
      final controller = WorkoutCompletionController(
        repository: repository,
        tamagotchi: tamagotchi,
      );

      await controller.confirm(const [_bench]);

      expect(controller.isConfirmed, isTrue);
      expect(repository.completed, hasLength(1));
      expect(
        tamagotchi.massOf(MuscleTamagotchiGroup.chest),
        greaterThan(0.5),
      );
    });

    test('undoing clears the record and reverses the avatar', () async {
      final repository = _RecordingRepository();
      final tamagotchi = MuscleTamagotchiState()..applyNutrition(1000);
      final fullnessAfterFeed = tamagotchi.coreFullness;
      final controller = WorkoutCompletionController(
        repository: repository,
        tamagotchi: tamagotchi,
      );
      await controller.confirm(const [_bench]);
      final grown = tamagotchi.massOf(MuscleTamagotchiGroup.chest);

      await controller.undo();

      expect(controller.isConfirmed, isFalse);
      expect(repository.completed, isEmpty);
      expect(
        tamagotchi.massOf(MuscleTamagotchiGroup.chest),
        lessThan(grown),
      );
      expect(
        tamagotchi.coreFullness,
        greaterThan(fullnessAfterFeed - 0.15),
      );
    });

    test('undo is a no-op when nothing is confirmed', () async {
      final repository = _RecordingRepository();
      final controller = WorkoutCompletionController(repository: repository);
      await controller.undo();
      expect(controller.isConfirmed, isFalse);
    });
  });

  group('M41 routines toggle widget', () {
    testWidgets('toggles the workout confirmation and reverses it', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1000, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final tamagotchi = MuscleTamagotchiState();
      final completion = WorkoutCompletionController(tamagotchi: tamagotchi);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: RoutinesPage(
              controller: ProjectionController(
                repository: MockProjectionRepository(),
              ),
              detailController: BodyDetailController(
                repository: MockBodyDetailRepository(),
                advisor: const RuleBasedMuscleGapAdvisor(),
              ),
              workoutCompletionController: completion,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      SwitchListTile toggle() => tester.widget<SwitchListTile>(
            find.byKey(const Key('confirm_workout_toggle')),
          );
      expect(toggle().value, isFalse);

      await tester.tap(find.byKey(const Key('confirm_workout_toggle')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('exercise_completion_close')));
      await tester.pumpAndSettle();

      expect(completion.isConfirmed, isTrue);
      expect(toggle().value, isTrue);
      expect(
        tamagotchi.massOf(MuscleTamagotchiGroup.chest),
        greaterThan(0.5),
      );

      await tester.tap(find.byKey(const Key('confirm_workout_toggle')));
      await tester.pumpAndSettle();

      expect(completion.isConfirmed, isFalse);
      expect(toggle().value, isFalse);
    });
  });
}
