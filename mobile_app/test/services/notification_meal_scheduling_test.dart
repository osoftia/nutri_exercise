import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/mocks/mock_daily_log_repository.dart';
import 'package:nutri_mobile_app/core/services/local_notification_scheduler.dart';
import 'package:nutri_mobile_app/core/services/notification_service.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class _FakeNotificationsPlatform extends FlutterLocalNotificationsPlatform {}

class _RecordingScheduler implements NotificationScheduler {
  final List<int> cancelledIds = [];
  final List<int> scheduledIds = [];
  final List<String?> bodies = [];
  final List<String?> payloads = [];
  final List<NotificationDetails> details = [];
  final List<tz.TZDateTime> dates = [];

  @override
  Future<void> cancel(int id) async {
    cancelledIds.add(id);
  }

  @override
  Future<void> zonedSchedule(
    int id,
    String? title,
    String? body,
    tz.TZDateTime scheduledDate,
    NotificationDetails notificationDetails, {
    required AndroidScheduleMode androidScheduleMode,
    String? payload,
    DateTimeComponents? matchDateTimeComponents,
  }) async {
    scheduledIds.add(id);
    bodies.add(body);
    payloads.add(payload);
    details.add(notificationDetails);
    dates.add(scheduledDate);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    FlutterLocalNotificationsPlatform.instance = _FakeNotificationsPlatform();
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.UTC);
  });

  group('NotificationService.scheduleDailyMealReminders', () {
    test('schedules breakfast, lunch and dinner at 8, 13 and 19', () async {
      final scheduler = _RecordingScheduler();
      final service = NotificationService(scheduler: scheduler);

      await service.scheduleDailyMealReminders();

      expect(scheduler.scheduledIds, hasLength(3));
      final hours = scheduler.dates.map((d) => d.hour).toList()..sort();
      expect(hours, [8, 13, 19]);
    });

    test('cancels the previous reminder ids before rescheduling', () async {
      final scheduler = _RecordingScheduler();
      final service = NotificationService(scheduler: scheduler);

      await service.scheduleDailyMealReminders();

      expect(
        scheduler.cancelledIds,
        containsAll([
          NotificationService.breakfastReminderId,
          NotificationService.lunchReminderId,
          NotificationService.dinnerReminderId,
        ]),
      );
      expect(
        scheduler.scheduledIds,
        containsAll([
          NotificationService.breakfastReminderId,
          NotificationService.lunchReminderId,
          NotificationService.dinnerReminderId,
        ]),
      );
    });

    test('injects the default meals as actions when no repository is given',
        () async {
      final scheduler = _RecordingScheduler();
      final service = NotificationService(scheduler: scheduler);

      await service.scheduleDailyMealReminders();

      final breakfast = scheduler.details
          .elementAt(scheduler.scheduledIds.indexOf(NotificationService.breakfastReminderId));
      final actions = breakfast.android!.actions!;
      expect(
        actions.map((a) => a.id).toList(),
        ['meal:Huevos con arepa', 'meal:Avena', 'meal:Frutas'],
      );
    });

    test('injects history-based meals as actions when a repository is provided',
        () async {
      final scheduler = _RecordingScheduler();
      final repo = MockDailyLogRepository(
        topMeals: {'lunch': ['Arepa de huevo', 'Bandeja paisa', 'Mondongo']},
      );
      final service = NotificationService(
        scheduler: scheduler,
        dailyLogRepository: repo,
      );

      await service.scheduleDailyMealReminders();

      final lunch = scheduler.details.elementAt(
        scheduler.scheduledIds.indexOf(NotificationService.lunchReminderId),
      );
      final actions = lunch.android!.actions!;
      expect(actions.map((a) => a.title).toList(), [
        'Arepa de huevo',
        'Bandeja paisa',
        'Mondongo',
      ]);
    });

    test('carries the meal slot in the payload', () async {
      final scheduler = _RecordingScheduler();
      final service = NotificationService(scheduler: scheduler);

      await service.scheduleDailyMealReminders();

      expect(scheduler.payloads, containsAll(['breakfast', 'lunch', 'dinner']));
    });
  });

  group('NotificationService meal action ids', () {
    test('mealActionId and mealNameFromActionId round-trip', () {
      final id = NotificationService.mealActionId('Pechuga con arroz');
      expect(NotificationService.mealNameFromActionId(id), 'Pechuga con arroz');
      expect(NotificationService.mealNameFromActionId('other'), isNull);
    });
  });
}