import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/mocks/mock_daily_entry_repository.dart';
import 'package:nutri_mobile_app/core/mocks/mock_symptom_repository.dart';
import 'package:nutri_mobile_app/core/models/daily_entry.dart';
import 'package:nutri_mobile_app/core/models/symptom_log.dart';
import 'package:nutri_mobile_app/core/services/local_notification_scheduler.dart';
import 'package:nutri_mobile_app/core/services/notification_service.dart';
import 'package:nutri_mobile_app/core/state/notification_navigation_controller.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class _FakeNotificationsPlatform extends FlutterLocalNotificationsPlatform {}

class _RecordingScheduler implements NotificationScheduler {
  final List<int> cancelledIds = [];
  final List<int> scheduledIds = [];
  final List<String?> titles = [];
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
    titles.add(title);
    bodies.add(body);
    details.add(notificationDetails);
    dates.add(scheduledDate);
    components.add(matchDateTimeComponents);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final today = DailyEntry.dateKey(DateTime.now());

  setUpAll(() {
    FlutterLocalNotificationsPlatform.instance = _FakeNotificationsPlatform();
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.UTC);
  });

  group('NotificationService.scheduleNightlyCheckIn (M45 Task 3)', () {
    test('schedules a daily 20:30 check-in when nothing is logged', () async {
      final scheduler = _RecordingScheduler();
      final service = NotificationService(scheduler: scheduler);

      await service.scheduleNightlyCheckIn(
        symptomRepository: MockSymptomRepository(),
        entryRepository: MockDailyEntryRepository(),
      );

      expect(
        scheduler.scheduledIds,
        [NotificationService.nightlyCheckInId],
      );
      expect(scheduler.dates.first.hour, 20);
      expect(scheduler.dates.first.minute, 30);
      expect(scheduler.components.first, DateTimeComponents.time);
    });

    test('includes symptom and activity icon actions', () async {
      final scheduler = _RecordingScheduler();
      final service = NotificationService(scheduler: scheduler);

      await service.scheduleNightlyCheckIn(
        symptomRepository: MockSymptomRepository(),
        entryRepository: MockDailyEntryRepository(),
      );

      final actions = scheduler.details.first.android!.actions!;
      expect(
        actions.map((a) => a.id).toList(),
        [
          NotificationService.symptomCheckInActionId,
          NotificationService.activityCheckInActionId,
        ],
      );
      // Rich, icon-bearing actions rather than plain text buttons.
      for (final action in actions) {
        expect(action.icon, isA<AndroidBitmap<Object>>());
      }
    });

    test('is rich-formatted with a big-text style', () async {
      final scheduler = _RecordingScheduler();
      final service = NotificationService(scheduler: scheduler);

      await service.scheduleNightlyCheckIn(
        symptomRepository: MockSymptomRepository(),
        entryRepository: MockDailyEntryRepository(),
      );

      expect(
        scheduler.details.first.android!.styleInformation,
        isA<BigTextStyleInformation>(),
      );
    });

    test('cancels the previous reminder id before rescheduling', () async {
      final scheduler = _RecordingScheduler();
      final service = NotificationService(scheduler: scheduler);

      await service.scheduleNightlyCheckIn(
        symptomRepository: MockSymptomRepository(),
        entryRepository: MockDailyEntryRepository(),
      );

      expect(
        scheduler.cancelledIds,
        contains(NotificationService.nightlyCheckInId),
      );
    });

    test('skips the reminder when symptoms and activity are already logged',
        () async {
      final scheduler = _RecordingScheduler();
      final service = NotificationService(scheduler: scheduler);

      await service.scheduleNightlyCheckIn(
        symptomRepository: MockSymptomRepository([
          SymptomLog(date: today, symptom: SymptomType.pain, level: 1),
        ]),
        entryRepository: MockDailyEntryRepository({
          today: DailyEntry(date: today, exercises: const ['Squat']),
        }),
      );

      expect(scheduler.scheduledIds, isEmpty);
      expect(
        scheduler.cancelledIds,
        contains(NotificationService.nightlyCheckInId),
      );
    });

    test('prompts for symptoms only when activity is already logged', () async {
      final scheduler = _RecordingScheduler();
      final service = NotificationService(scheduler: scheduler);

      await service.scheduleNightlyCheckIn(
        symptomRepository: MockSymptomRepository(),
        entryRepository: MockDailyEntryRepository({
          today: DailyEntry(date: today, calories: 1500),
        }),
      );

      expect(scheduler.scheduledIds, [NotificationService.nightlyCheckInId]);
      expect(
        scheduler.bodies.first,
        NotificationService.nightlyCheckInBodySymptoms,
      );
    });

    test('prompts for activity only when symptoms are already logged',
        () async {
      final scheduler = _RecordingScheduler();
      final service = NotificationService(scheduler: scheduler);

      await service.scheduleNightlyCheckIn(
        symptomRepository: MockSymptomRepository([
          SymptomLog(date: today, symptom: SymptomType.energy, level: 2),
        ]),
        entryRepository: MockDailyEntryRepository(),
      );

      expect(scheduler.scheduledIds, [NotificationService.nightlyCheckInId]);
      expect(
        scheduler.bodies.first,
        NotificationService.nightlyCheckInBodyActivity,
      );
    });
  });

  group('nightlyCheckInBody', () {
    test('mentions both logs when both are missing', () {
      expect(
        NotificationService.nightlyCheckInBody(
          needsSymptoms: true,
          needsActivity: true,
        ),
        NotificationService.nightlyCheckInBodyBoth,
      );
    });

    test('never returns a blank body', () {
      for (final needsSymptoms in [true, false]) {
        for (final needsActivity in [true, false]) {
          expect(
            NotificationService.nightlyCheckInBody(
              needsSymptoms: needsSymptoms,
              needsActivity: needsActivity,
            ).trim(),
            isNotEmpty,
          );
        }
      }
    });
  });

  group('nightly check-in routing (M45 Task 3)', () {
    test('requestSymptoms sets and clears the pending action', () {
      final nav = NotificationNavigationController();

      nav.requestSymptoms();
      expect(nav.pending, NotificationAction.openSymptoms);

      nav.consume();
      expect(nav.pending, isNull);
    });
  });
}
