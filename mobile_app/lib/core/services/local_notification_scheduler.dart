import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

/// Minimal seam over `flutter_local_notifications` timezone scheduling so tests
/// can record the scheduled reminders without touching platform channels.
abstract interface class NotificationScheduler {
  Future<void> cancel(int id);

  Future<void> zonedSchedule(
    int id,
    String? title,
    String? body,
    tz.TZDateTime scheduledDate,
    NotificationDetails notificationDetails, {
    required AndroidScheduleMode androidScheduleMode,
    String? payload,
    DateTimeComponents? matchDateTimeComponents,
  });
}

/// Production [NotificationScheduler] that delegates to the plugin.
class FlutterLocalNotificationScheduler implements NotificationScheduler {
  FlutterLocalNotificationScheduler(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;

  @override
  Future<void> cancel(int id) => _plugin.cancel(id);

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
  }) {
    return _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      notificationDetails,
      androidScheduleMode: androidScheduleMode,
      payload: payload,
      matchDateTimeComponents: matchDateTimeComponents,
    );
  }
}
