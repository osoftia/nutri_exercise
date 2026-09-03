import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/services/local_notification_scheduler.dart';
import 'package:nutri_mobile_app/core/services/notification_service.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class _FakeNotificationsPlatform extends FlutterLocalNotificationsPlatform {}

class _RecordingScheduler implements NotificationScheduler {
  final List<int> cancelledIds = [];
  final List<tz.TZDateTime> scheduledDates = [];
  final List<DateTimeComponents?> matchComponents = [];
  final List<String?> bodies = [];

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
    scheduledDates.add(scheduledDate);
    matchComponents.add(matchDateTimeComponents);
    bodies.add(body);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    FlutterLocalNotificationsPlatform.instance = _FakeNotificationsPlatform();
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.UTC);
  });

  group('NotificationService', () {
    test('initialize is idempotent', () async {
      final service = NotificationService();

      await service.initialize();
      await service.initialize();
    });

    test('scheduleWeeklyRoutine completes without throwing', () async {
      final service = NotificationService();

      await service.scheduleWeeklyRoutine(1, 3);
    });

    test('nextDailyOccurrence returns today when before the reminder time',
        () {
      final now = tz.TZDateTime(tz.UTC, 2026, 9, 3, 10, 0);

      final next = NotificationService.nextDailyOccurrence(now);

      expect(next.year, 2026);
      expect(next.month, 9);
      expect(next.day, 3);
      expect(next.hour, 20);
      expect(next.minute, 0);
    });

    test('nextDailyOccurrence rolls to tomorrow when after the reminder time',
        () {
      final now = tz.TZDateTime(tz.UTC, 2026, 9, 3, 21, 30);

      final next = NotificationService.nextDailyOccurrence(now);

      expect(next.day, 4);
      expect(next.hour, 20);
      expect(next.minute, 0);
    });

    test('scheduleDailyReminder cancels then schedules at 20:00', () async {
      final scheduler = _RecordingScheduler();
      final service = NotificationService(scheduler: scheduler);

      await service.scheduleDailyReminder();

      expect(scheduler.cancelledIds, contains(NotificationService.dailyReminderId));
      expect(scheduler.scheduledDates, hasLength(1));
      expect(scheduler.scheduledDates.first.hour, 20);
      expect(scheduler.scheduledDates.first.minute, 0);
      expect(scheduler.matchComponents.first, DateTimeComponents.time);
    });

    test('scheduleDailyReminder uses the daily check-in message', () async {
      final scheduler = _RecordingScheduler();
      final service = NotificationService(scheduler: scheduler);

      await service.scheduleDailyReminder();

      expect(scheduler.bodies.first, 'What did you eat and train today?');
    });

    test('scheduleDailyReminder honors a custom hour and minute', () async {
      final scheduler = _RecordingScheduler();
      final service = NotificationService(scheduler: scheduler);

      await service.scheduleDailyReminder(hour: 7, minute: 30);

      expect(scheduler.scheduledDates.first.hour, 7);
      expect(scheduler.scheduledDates.first.minute, 30);
    });
  });
}
