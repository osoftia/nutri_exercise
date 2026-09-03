import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'local_notification_scheduler.dart';

/// Configures the timezone database and pins [tz.local] to a fixed-offset
/// location derived from the device's current UTC offset.
///
/// A full IANA zone lookup (e.g. via `flutter_timezone`) is a follow-up; this
/// fixed offset is sufficient for a daily wall-clock reminder and is resilient
/// on every platform.
void configureLocalTimeZone() {
  tzdata.initializeTimeZones();
  final offset = DateTime.now().timeZoneOffset;
  tz.setLocalLocation(
    tz.Location(
      'local',
      <int>[],
      <int>[],
      <tz.TimeZone>[
        tz.TimeZone(
          offset.inMilliseconds,
          isDst: false,
          abbreviation: 'local',
        ),
      ],
    ),
  );
}

/// Wraps `flutter_local_notifications` for weekly and daily reminders.
class NotificationService {
  NotificationService({
    FlutterLocalNotificationsPlugin? plugin,
    NotificationScheduler? scheduler,
    void Function(String? payload)? onTap,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
       _onTap = onTap {
    _scheduler = scheduler ?? FlutterLocalNotificationScheduler(_plugin);
  }

  static const String _channelId = 'routine_reminders';
  static const String _channelName = 'Routine reminders';
  static const String _channelDescription =
      'Weekly reminders for scheduled workouts';

  static const String _dailyChannelId = 'daily_log_reminders';
  static const String _dailyChannelName = 'Daily check-in';
  static const String _dailyChannelDescription =
      'A daily nudge to log what you ate and trained';
  static const String _dailyReminderTitle = 'Daily check-in';
  static const String _dailyReminderBody = 'What did you eat and train today?';

  /// Stable id used for the daily reminder so rescheduling replaces it.
  static const int dailyReminderId = 2001;

  final FlutterLocalNotificationsPlugin _plugin;
  late final NotificationScheduler _scheduler;
  final void Function(String? payload)? _onTap;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      ),
      macOS: DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      ),
    );
    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse:
          _onTap == null ? null : _handleResponse,
    );
    _initialized = true;
  }

  void _handleResponse(NotificationResponse response) {
    _onTap?.call(response.payload);
  }

  /// Simulates scheduling a weekly local notification for the selected routine.
  Future<void> scheduleWeeklyRoutine(int routineId, int dayOfWeek) async {
    await initialize();
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
      macOS: DarwinNotificationDetails(),
    );
    await _plugin.periodicallyShow(
      routineId,
      'Routine reminder',
      'Time for your Day $dayOfWeek workout',
      RepeatInterval.weekly,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  /// Schedules the daily check-in reminder at [hour]:[minute] local time.
  ///
  /// Cancels any previous daily reminder first so relaunching never stacks
  /// duplicates.
  Future<void> scheduleDailyReminder({int hour = 20, int minute = 0}) async {
    await initialize();
    final scheduled = nextDailyOccurrence(
      tz.TZDateTime.now(tz.local),
      hour: hour,
      minute: minute,
    );
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _dailyChannelId,
        _dailyChannelName,
        channelDescription: _dailyChannelDescription,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
      macOS: DarwinNotificationDetails(),
    );
    await _scheduler.cancel(dailyReminderId);
    await _scheduler.zonedSchedule(
      dailyReminderId,
      _dailyReminderTitle,
      _dailyReminderBody,
      scheduled,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Returns whether the app was launched by tapping a notification.
  Future<NotificationAppLaunchDetails?> launchDetails() =>
      _plugin.getNotificationAppLaunchDetails();

  /// The next [hour]:[minute] wall-clock occurrence at or after [now], rolling
  /// to tomorrow when [now] is already past that time.
  static tz.TZDateTime nextDailyOccurrence(
    tz.TZDateTime now, {
    int hour = 20,
    int minute = 0,
  }) {
    var scheduled = tz.TZDateTime(
      now.location,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
