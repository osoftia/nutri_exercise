import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/domain/notifications/exercise_check_in.dart';
import 'package:nutri_mobile_app/core/domain/popups/exercise_completion.dart';
import 'package:nutri_mobile_app/core/mocks/mock_body_detail_repository.dart';
import 'package:nutri_mobile_app/core/mocks/mock_daily_entry_repository.dart';
import 'package:nutri_mobile_app/core/mocks/mock_meal_action_repository.dart';
import 'package:nutri_mobile_app/core/mocks/mock_tamagotchi_progress_repository.dart';
import 'package:nutri_mobile_app/core/models/daily_entry.dart';
import 'package:nutri_mobile_app/core/models/tamagotchi_progress.dart';
import 'package:nutri_mobile_app/core/services/notification_background_handler.dart';
import 'package:nutri_mobile_app/core/services/notification_service.dart';
import 'package:nutri_mobile_app/core/state/muscle_tamagotchi_state.dart';
import 'package:nutri_mobile_app/core/utils/weekly_stats.dart';

class _RecordingAndroidPlatform extends AndroidFlutterLocalNotificationsPlugin {
  final List<int> cancelledIds = [];

  @override
  Future<void> cancel(int id, {String? tag}) async {
    cancelledIds.add(id);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('meal action logs the meal, applies bloat math and clears the notification',
      () async {
    final meals = MockMealActionRepository();
    final progress = MockTamagotchiProgressRepository(
      const TamagotchiProgress(coreFullness: 0.5),
    );
    final platform = _RecordingAndroidPlatform();
    FlutterLocalNotificationsPlatform.instance = platform;
    final plugin = FlutterLocalNotificationsPlugin();

    await handleNotificationResponse(
      NotificationResponse(
        id: NotificationService.breakfastReminderId,
        actionId: NotificationService.mealActionId('Avena'),
        payload: 'breakfast',
        notificationResponseType: NotificationResponseType.selectedNotificationAction,
      ),
      mealRepository: meals,
      progressRepository: progress,
      plugin: plugin,
    );

    final logged = await meals.getByDate(DailyEntry.dateKey(DateTime.now()));
    expect(logged, hasLength(1));
    expect(logged.first.meal, 'Avena');
    expect(logged.first.timeOfDay, 'breakfast');

    final saved = await progress.get();
    expect(saved, isNotNull);
    expect(saved!.coreFullness, greaterThan(0.5));
    expect(saved.coreFullness, lessThanOrEqualTo(1.0));

    expect(platform.cancelledIds, contains(NotificationService.breakfastReminderId));
  });

  test('non-meal actions do not log a meal or touch progress', () async {
    final meals = MockMealActionRepository();
    final progress = MockTamagotchiProgressRepository();
    final platform = _RecordingAndroidPlatform();
    FlutterLocalNotificationsPlatform.instance = platform;
    final plugin = FlutterLocalNotificationsPlugin();

    await handleNotificationResponse(
      NotificationResponse(
        id: 1,
        payload: 'breakfast',
        notificationResponseType: NotificationResponseType.selectedNotificationAction,
      ),
      mealRepository: meals,
      progressRepository: progress,
      plugin: plugin,
    );

    expect(await meals.getAll(), isEmpty);
    expect(await progress.get(), isNull);
    expect(platform.cancelledIds, contains(1));
  });

  test('bloat math is pure and clamps within [0, 1]', () {
    expect(MuscleTamagotchiState.coreFullnessAfterNutrition(0.9, 2000), 1.0);
    expect(
      MuscleTamagotchiState.coreFullnessAfterNutrition(0.4, 1000),
      0.9,
    );
    expect(MuscleTamagotchiState.coreFullnessAfterSlimming(0.1), 0.0);
    expect(
      MuscleTamagotchiState.coreFullnessAfterSlimming(0.5, amount: 0.2),
      0.3,
    );
  });

  test('exercise_yes responses are dispatched and record the burned calories',
      () async {
    final entries = MockDailyEntryRepository()
      ..save(DailyEntry(
        date: DailyEntry.dateKey(DateTime.now()),
        exercises: const ['Squat'],
      ));
    final progress = MockTamagotchiProgressRepository(
      const TamagotchiProgress(coreFullness: 0.8),
    );
    final platform = _RecordingAndroidPlatform();
    FlutterLocalNotificationsPlatform.instance = platform;
    final plugin = FlutterLocalNotificationsPlugin();

    await handleNotificationResponse(
      NotificationResponse(
        id: 99,
        actionId: NotificationService.exerciseYesActionId,
        notificationResponseType: NotificationResponseType.selectedNotificationAction,
      ),
      dailyEntryRepository: entries,
      progressRepository: progress,
      bodyDetailRepository: MockBodyDetailRepository(),
      plugin: plugin,
    );

    expect(
      (await entries.getByDate(DailyEntry.dateKey(DateTime.now())))!.burned,
      caloriesBurnedPerExercise,
    );
    expect((await progress.get())!.coreFullness, lessThan(0.8));
    expect(platform.cancelledIds, contains(99));
  });

  test('exercise_yes with a structured payload persists its completions',
      () async {
    final entries = MockDailyEntryRepository()
      ..save(DailyEntry(
        date: DailyEntry.dateKey(DateTime.now()),
        exercises: const ['Bench Press'],
      ));
    final bodyDetail = MockBodyDetailRepository();
    final platform = _RecordingAndroidPlatform();
    FlutterLocalNotificationsPlatform.instance = platform;
    final plugin = FlutterLocalNotificationsPlugin();
    final payload = const ExerciseCheckIn(
      exercises: [
        CompletedExercise(
          name: 'Bench Press',
          plannedSets: 4,
          completedSets: 3,
          reps: 8,
          loadKg: 60,
        ),
      ],
    ).encode();

    await handleNotificationResponse(
      NotificationResponse(
        id: 100,
        actionId: NotificationService.exerciseYesActionId,
        payload: payload,
        notificationResponseType:
            NotificationResponseType.selectedNotificationAction,
      ),
      dailyEntryRepository: entries,
      progressRepository: MockTamagotchiProgressRepository(),
      bodyDetailRepository: bodyDetail,
      plugin: plugin,
    );

    final saved = await bodyDetail.loadCompletedExercises();
    expect(saved, hasLength(1));
    expect(saved.single.completedSets, 3);
    expect(saved.single.plannedSets, 4);
    expect(saved.single.loadKg, 60);
  });
}