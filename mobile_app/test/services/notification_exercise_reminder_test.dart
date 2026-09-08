import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/services/local_notification_scheduler.dart';
import 'package:nutri_mobile_app/core/services/notification_service.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class _FakeNotificationsPlatform extends FlutterLocalNotificationsPlatform {}

class _RecordingScheduler implements NotificationScheduler {
  final List<int> cancelledIds = [];
  final List<int> scheduledIds = [];
  final List<String?> bodies = [];
  final List<NotificationDetails> details = [];
  final List<tz.TZDateTime> dates = [];
  final List<DateTimeComponents?> components = [];

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
    details.add(notificationDetails);
    dates.add(scheduledDate);
    components.add(matchDateTimeComponents);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    FlutterLocalNotificationsPlatform.instance = _FakeNotificationsPlatform();
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.UTC);
  });

  group('NotificationService.scheduleDailyExerciseReminder', () {
    test('schedules a daily 21:00 reminder', () async {
      final scheduler = _RecordingScheduler();
      final service = NotificationService(scheduler: scheduler);

      await service.scheduleDailyExerciseReminder();

      expect(scheduler.scheduledIds, [NotificationService.exerciseReminderId]);
      expect(scheduler.dates.first.hour, 21);
      expect(scheduler.dates.first.minute, 0);
      expect(scheduler.components.first, DateTimeComponents.time);
    });

    test('includes Yes and Not-yet action buttons', () async {
      final scheduler = _RecordingScheduler();
      final service = NotificationService(scheduler: scheduler);

      await service.scheduleDailyExerciseReminder();

      final actions = scheduler.details.first.android!.actions!;
      expect(
        actions.map((a) => a.id).toList(),
        [
          NotificationService.exerciseYesActionId,
          NotificationService.exerciseNoActionId,
        ],
      );
      expect(actions.map((a) => a.title).toList(), ['Yes', 'Not yet']);
    });

    test('cancels the previous reminder id before rescheduling', () async {
      final scheduler = _RecordingScheduler();
      final service = NotificationService(scheduler: scheduler);

      await service.scheduleDailyExerciseReminder();

      expect(
        scheduler.cancelledIds,
        contains(NotificationService.exerciseReminderId),
      );
    });

    test('asks whether routines were completed', () async {
      final scheduler = _RecordingScheduler();
      final service = NotificationService(scheduler: scheduler);

      await service.scheduleDailyExerciseReminder();

      expect(
        scheduler.bodies.first,
        'Did you complete your workout routines today?',
      );
    });
  });
}