import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/data/body_detail_repository.dart';
import 'package:nutri_mobile_app/core/domain/body_projection/body_segment.dart';
import 'package:nutri_mobile_app/core/domain/body_projection/muscle_workout_log.dart';
import 'package:nutri_mobile_app/core/domain/body_projection/nutrition_log.dart';
import 'package:nutri_mobile_app/core/domain/popups/exercise_completion.dart';
import 'package:nutri_mobile_app/core/mocks/mock_daily_entry_repository.dart';
import 'package:nutri_mobile_app/core/mocks/mock_tamagotchi_progress_repository.dart';
import 'package:nutri_mobile_app/core/models/daily_entry.dart';
import 'package:nutri_mobile_app/core/services/exercise_response_handler.dart';
import 'package:nutri_mobile_app/core/services/notification_service.dart';
import 'package:nutri_mobile_app/core/services/rule_based_muscle_gap_advisor.dart';
import 'package:nutri_mobile_app/core/state/body_detail_controller.dart';
import 'package:nutri_mobile_app/core/state/muscle_tamagotchi_state.dart';
import 'package:nutri_mobile_app/core/state/workout_completion_controller.dart';

class _RecordingRepository implements BodyDetailRepository {
  DailyFoodLog foodLog = const DailyFoodLog();
  List<CompletedExercise> completed = const [];

  final List<DailyFoodLog> savedFoodLogs = [];
  int saveCompletionsCalls = 0;
  List<CompletedExercise>? lastSavedCompletions;

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
  Future<List<CompletedExercise>> loadCompletedExercises() async => completed;

  @override
  Future<void> saveCompletedExercises(List<CompletedExercise> exercises) async {
    completed = exercises;
    saveCompletionsCalls++;
    lastSavedCompletions = exercises;
  }
}

const _benchPress = CompletedExercise(
  name: 'Bench Press',
  plannedSets: 4,
  completedSets: 4,
  reps: 8,
  loadKg: 60,
);

void main() {
  group('M39 controller persistence', () {
    test('adding a food persists the whole log and bloats the avatar', () async {
      final repository = _RecordingRepository();
      final tamagotchi = MuscleTamagotchiState();
      final controller = BodyDetailController(
        repository: repository,
        advisor: const RuleBasedMuscleGapAdvisor(),
        tamagotchi: tamagotchi,
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
      expect(repository.savedFoodLogs.last.entries.single.name, 'Protein Shake');
      expect(tamagotchi.coreFullness, greaterThan(0));
    });

    test('removing a food persists the remaining log', () async {
      final repository = _RecordingRepository()
        ..foodLog = const DailyFoodLog(
          entries: [
            LoggedFood(name: 'A', portion: '1', calories: 100, time: '08:00'),
            LoggedFood(name: 'B', portion: '1', calories: 200, time: '12:00'),
            LoggedFood(name: 'C', portion: '1', calories: 300, time: '18:00'),
          ],
        );
      final controller = BodyDetailController(
        repository: repository,
        advisor: const RuleBasedMuscleGapAdvisor(),
      );
      await controller.loadFoodLog();

      await controller.removeFood(0);

      expect(repository.savedFoodLogs.last.entries, hasLength(2));
      expect(repository.savedFoodLogs.last.entries.first.name, 'B');
    });

    test('completedExercises reads the repository', () async {
      final repository = _RecordingRepository()..completed = const [_benchPress];
      final controller = BodyDetailController(
        repository: repository,
        advisor: const RuleBasedMuscleGapAdvisor(),
      );

      final completed = await controller.completedExercises();

      expect(completed, hasLength(1));
      expect(completed.single.name, 'Bench Press');
    });
  });

  group('M39 workout completion persistence', () {
    test('confirm persists and summarises the completions', () async {
      final repository = _RecordingRepository();
      final controller = WorkoutCompletionController(repository: repository);

      await controller.confirm(const [_benchPress]);

      expect(repository.saveCompletionsCalls, 1);
      expect(repository.lastSavedCompletions, hasLength(1));
      expect(controller.summary!.caloriesBurned, 250);
    });

    test('present summarises persisted completions without saving again', () {
      final repository = _RecordingRepository();
      final controller = WorkoutCompletionController(repository: repository);

      controller.present(const [_benchPress]);

      expect(repository.saveCompletionsCalls, 0);
      expect(controller.summary, isNotNull);
      expect(controller.summary!.caloriesBurned, 250);
    });
  });

  group('M39 notification handler persistence', () {
    test('the 9 PM action records the completed exercise names', () async {
      final today = DailyEntry.dateKey(DateTime.now());
      final entries = MockDailyEntryRepository()
        ..save(DailyEntry(date: today, exercises: const ['Squat', 'Bench Press']));
      final repository = _RecordingRepository();

      await ExerciseResponseHandler.handleExerciseResponse(
        actionId: NotificationService.exerciseYesActionId,
        entries: entries,
        progress: MockTamagotchiProgressRepository(),
        completions: repository,
      );

      expect(repository.saveCompletionsCalls, 1);
      expect(
        repository.lastSavedCompletions!.map((e) => e.name),
        containsAll(const ['Squat', 'Bench Press']),
      );
    });
  });
}
