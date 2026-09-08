import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/mocks/mock_daily_entry_repository.dart';
import 'package:nutri_mobile_app/core/mocks/mock_tamagotchi_progress_repository.dart';
import 'package:nutri_mobile_app/core/models/daily_entry.dart';
import 'package:nutri_mobile_app/core/models/tamagotchi_progress.dart';
import 'package:nutri_mobile_app/core/services/exercise_response_handler.dart';
import 'package:nutri_mobile_app/core/services/notification_service.dart';
import 'package:nutri_mobile_app/core/state/muscle_tamagotchi_state.dart';
import 'package:nutri_mobile_app/core/utils/weekly_stats.dart';

void main() {
  final today = DailyEntry.dateKey(DateTime.now());

  group('ExerciseResponseHandler math', () {
    test('caloriesBurnedFor scales per exercise', () {
      expect(ExerciseResponseHandler.caloriesBurnedFor(const []), 0);
      expect(
        ExerciseResponseHandler.caloriesBurnedFor(const ['Squat', 'Bench Press']),
        2 * caloriesBurnedPerExercise,
      );
    });

    test('slimmedFullness reduces fullness per exercise and clamps', () {
      expect(
        ExerciseResponseHandler.slimmedFullness(
          1.0,
          const ['Squat'],
        ),
        MuscleTamagotchiState.coreFullnessAfterSlimming(
          1.0,
          amount: MuscleTamagotchiState.slimmingPerExercise,
        ),
      );
      expect(
        ExerciseResponseHandler.slimmedFullness(0.1, const ['Squat']),
        0.0,
      );
    });
  });

  group('ExerciseResponseHandler.handle', () {
    test('confirming a workout records burned calories and slims the core', () async {
      final entries = MockDailyEntryRepository()
        ..save(DailyEntry(
          date: today,
          exercises: const ['Squat', 'Bench Press'],
        ));
      final progress = MockTamagotchiProgressRepository(
        const TamagotchiProgress(coreFullness: 0.9),
      );

      await ExerciseResponseHandler.handleExerciseResponse(
        actionId: NotificationService.exerciseYesActionId,
        entries: entries,
        progress: progress,
      );

      final entry = await entries.getByDate(today);
      expect(entry!.burned, 2 * caloriesBurnedPerExercise);

      final saved = await progress.get();
      expect(saved!.coreFullness, lessThan(0.9));
    });

    test('"Not yet" changes nothing', () async {
      final entries = MockDailyEntryRepository()
        ..save(DailyEntry(
          date: today,
          exercises: const ['Squat'],
          calories: 100,
        ));
      final progress = MockTamagotchiProgressRepository(
        const TamagotchiProgress(coreFullness: 0.5),
      );

      await ExerciseResponseHandler.handleExerciseResponse(
        actionId: NotificationService.exerciseNoActionId,
        entries: entries,
        progress: progress,
      );

      expect((await entries.getByDate(today))!.burned, 0);
      expect((await progress.get())!.coreFullness, 0.5);
    });

    test('a workout with no logged exercises records zero burned', () async {
      final entries = MockDailyEntryRepository();
      final progress = MockTamagotchiProgressRepository();

      await ExerciseResponseHandler.handleExerciseResponse(
        actionId: NotificationService.exerciseYesActionId,
        entries: entries,
        progress: progress,
      );

      expect((await entries.getByDate(today))!.burned, 0);
    });
  });
}