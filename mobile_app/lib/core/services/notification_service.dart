import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const String _channelId = 'routine_reminders';
  static const String _channelName = 'Routine reminders';
  static const String _channelDescription =
      'Weekly reminders for scheduled workouts';

  final FlutterLocalNotificationsPlugin _plugin;
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
    await _plugin.initialize(settings);
    _initialized = true;
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
}
