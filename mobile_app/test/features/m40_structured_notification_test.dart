import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/data/body_detail_repository.dart';
import 'package:nutri_mobile_app/core/domain/body_projection/body_segment.dart';
import 'package:nutri_mobile_app/core/domain/body_projection/muscle_workout_log.dart';
import 'package:nutri_mobile_app/core/domain/body_projection/nutrition_log.dart';
import 'package:nutri_mobile_app/core/domain/notifications/exercise_check_in.dart';
import 'package:nutri_mobile_app/core/domain/popups/exercise_completion.dart';
import 'package:nutri_mobile_app/core/mocks/mock_body_detail_repository.dart';
import 'package:nutri_mobile_app/core/mocks/mock_daily_entry_repository.dart';
import 'package:nutri_mobile_app/core/mocks/mock_tamagotchi_progress_repository.dart';
import 'package:nutri_mobile_app/core/models/daily_entry.dart';
import 'package:nutri_mobile_app/core/services/exercise_response_handler.dart';
import 'package:nutri_mobile_app/core/services/notification_service.dart';
import 'package:nutri_mobile_app/core/services/rule_based_muscle_gap_advisor.dart';
import 'package:nutri_mobile_app/core/state/body_detail_controller.dart';
import 'package:nutri_mobile_app/core/state/notification_navigation_controller.dart';

const _bench = CompletedExercise(
  name: 'Bench Press',
  plannedSets: 4,
  completedSets: 3,
  reps: 8,
  loadKg: 60,
);

class _RecordingRepository implements BodyDetailRepository {
  DailyFoodLog foodLog = const DailyFoodLog();
  List<CompletedExercise> completed = const [];
  List<CompletedExercise>? lastSaved;

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
    lastSaved = exercises;
  }
}

void main() {
  group('M40 ExerciseCheckIn codec', () {
    test('round-trips a structured check-in', () {
      const checkIn = ExerciseCheckIn(exercises: [_bench]);
      final encoded = checkIn.encode();

      final parsed = ExerciseCheckIn.tryParse(encoded);

      expect(parsed, isNotNull);
      expect(parsed!.exercises, hasLength(1));
      expect(parsed.exercises.single.name, 'Bench Press');
      expect(parsed.exercises.single.plannedSets, 4);
      expect(parsed.exercises.single.completedSets, 3);
      expect(parsed.exercises.single.reps, 8);
      expect(parsed.exercises.single.loadKg, 60);
      expect(parsed, equals(checkIn));
      expect(parsed.hashCode, equals(checkIn.hashCode));
      expect(checkIn.toString(), contains('ExerciseCheckIn'));
    });

    test('rejects malformed or foreign payloads', () {
      expect(ExerciseCheckIn.tryParse(null), isNull);
      expect(ExerciseCheckIn.tryParse(''), isNull);
      expect(ExerciseCheckIn.tryParse('not json'), isNull);
      expect(ExerciseCheckIn.tryParse('{"type":"other"}'), isNull);
      expect(ExerciseCheckIn.tryParse('{"type":"exercise_check_in"}'), isNull);
      expect(
        ExerciseCheckIn.tryParse(
          '{"type":"exercise_check_in","exercises":"nope"}',
        ),
        isNull,
      );
    });

    test('builds a one-set fallback from names', () {
      final fallback = ExerciseCheckIn.fromNames(const ['Squat', 'Bench Press']);

      expect(fallback.exercises, hasLength(2));
      expect(fallback.exercises.every((e) => e.completedSets == 1), isTrue);
      expect(fallback.isEmpty, isFalse);
      expect(ExerciseCheckIn.fromNames(const []).isEmpty, isTrue);
    });
  });

  group('M40 handler with a structured payload', () {
    test('persists the structured completions and burns per exercise', () async {
      final today = DailyEntry.dateKey(DateTime.now());
      final entries = MockDailyEntryRepository()
        ..save(DailyEntry(date: today, exercises: const ['Bench Press']));
      final repository = _RecordingRepository();
      final payload = const ExerciseCheckIn(exercises: [_bench]).encode();

      await ExerciseResponseHandler.handleExerciseResponse(
        actionId: NotificationService.exerciseYesActionId,
        entries: entries,
        progress: MockTamagotchiProgressRepository(),
        payload: payload,
        completions: repository,
      );

      expect(repository.lastSaved, hasLength(1));
      expect(repository.lastSaved!.single.completedSets, 3);
      expect(repository.lastSaved!.single.plannedSets, 4);
      expect(repository.lastSaved!.single.loadKg, 60);
      expect(
        (await entries.getByDate(today))!.burned,
        250,
      );
    });

    test('falls back to the stored exercise names without a payload', () async {
      final today = DailyEntry.dateKey(DateTime.now());
      final entries = MockDailyEntryRepository()
        ..save(DailyEntry(date: today, exercises: const ['Squat']));
      final repository = _RecordingRepository();

      await ExerciseResponseHandler.handleExerciseResponse(
        actionId: NotificationService.exerciseYesActionId,
        entries: entries,
        progress: MockTamagotchiProgressRepository(),
        completions: repository,
      );

      expect(repository.lastSaved, hasLength(1));
      expect(repository.lastSaved!.single.name, 'Squat');
      expect(repository.lastSaved!.single.completedSets, 1);
    });
  });

  group('M40 controller payload building', () {
    test('builds a payload that parses back to the planned exercises', () async {
      final controller = BodyDetailController(
        repository: MockBodyDetailRepository(),
        advisor: const RuleBasedMuscleGapAdvisor(),
      );
      await controller.loadOverview();

      final payload = controller.exerciseCheckInPayload();
      final parsed = ExerciseCheckIn.tryParse(payload);

      expect(parsed, isNotNull);
      expect(parsed!.exercises, isNotEmpty);
      expect(parsed.exercises.first.name, isNotEmpty);
      expect(
        parsed.exercises.map((e) => e.name).toSet(),
        controller.plannedExercises().map((e) => e.name).toSet(),
      );
    });
  });

  group('M40 navigation payload', () {
    test('carries the payload alongside the exercise action', () {
      final nav = NotificationNavigationController()
        ..requestExerciseCompletion(payload: '{"type":"exercise_check_in"}');

      expect(nav.pending, NotificationAction.exerciseCompleted);
      expect(nav.exercisePayload, '{"type":"exercise_check_in"}');

      nav.consume();
      expect(nav.pending, isNull);
      expect(nav.exercisePayload, isNull);
    });
  });
}
