import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../constants/meal_presets.dart';
import '../data/daily_entry_repository.dart';
import '../data/daily_log_repository.dart';
import '../models/daily_entry.dart';
import '../utils/weekly_stats.dart';
import 'local_notification_scheduler.dart';
import 'notification_background_handler.dart';

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
    void Function(String? actionId, String? payload)? onResponse,
    DailyLogRepository? dailyLogRepository,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
       _onResponse = onResponse,
       _dailyLogRepository = dailyLogRepository {
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

  /// Stable ids for the three interactive meal reminders.
  static const int breakfastReminderId = 3101;
  static const int lunchReminderId = 3102;
  static const int dinnerReminderId = 3103;

  /// Stable id for the immediate "meal logged" reactive notification.
  static const int mealLoggedNotificationId = 4001;

  /// Stable id for the daily 9 PM exercise check-in reminder.
  static const int exerciseReminderId = 3201;

  /// Stable id for the "EXERCISE NOT" test notification.
  static const int exerciseReminderTestId = 3202;

  /// Notification action ids for the exercise check-in.
  static const String exerciseYesActionId = 'exercise_yes';
  static const String exerciseNoActionId = 'exercise_no';

  static const String _exerciseChannelId = 'exercise_reminders';
  static const String _exerciseChannelName = 'Workout check-in';
  static const String _exerciseChannelDescription =
      'Asks if you completed your workout routines';
  static const String _exerciseTitle = 'Workout check-in';
  static const String _exerciseBody =
      'Did you complete your workout routines today?';

  NotificationDetails _exerciseDetails() => const NotificationDetails(
    android: AndroidNotificationDetails(
      _exerciseChannelId,
      _exerciseChannelName,
      channelDescription: _exerciseChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
      actions: [
        AndroidNotificationAction(
          exerciseYesActionId,
          'Yes',
          showsUserInterface: false,
        ),
        AndroidNotificationAction(
          exerciseNoActionId,
          'Not yet',
          showsUserInterface: false,
        ),
      ],
    ),
    iOS: DarwinNotificationDetails(),
    macOS: DarwinNotificationDetails(),
  );

  /// Immediately shows a test exercise check-in notification (used by the
  /// "EXERCISE NOT" button).
  Future<void> showExerciseReminderTest({String? payload}) async {
    await initialize();
    await _plugin.show(
      exerciseReminderTestId,
      _exerciseTitle,
      _exerciseBody,
      _exerciseDetails(),
      payload: payload,
    );
  }

  /// Schedules the daily 9:00 PM exercise check-in reminder (repeating every
  /// day). Cancels the previous reminder id first so relaunching never stacks
  /// duplicates.
  ///
  /// [payload] optionally carries the structured [ExerciseCheckIn] so the
  /// notification action has parity with the in-app manual check-in.
  Future<void> scheduleDailyExerciseReminder({String? payload}) async {
    await initialize();
    final scheduled = nextDailyOccurrence(
      tz.TZDateTime.now(tz.local),
      hour: 21,
      minute: 0,
    );
    await _scheduler.cancel(exerciseReminderId);
    await _scheduler.zonedSchedule(
      exerciseReminderId,
      _exerciseTitle,
      _exerciseBody,
      scheduled,
      _exerciseDetails(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: payload,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static const List<({int id, String timeOfDay, String title, int hour, int minute})>
  mealSlots = [
    (id: breakfastReminderId, timeOfDay: 'breakfast', title: 'Breakfast', hour: 8, minute: 0),
    (id: lunchReminderId, timeOfDay: 'lunch', title: 'Lunch', hour: 13, minute: 0),
    (id: dinnerReminderId, timeOfDay: 'dinner', title: 'Dinner', hour: 19, minute: 0),
  ];

  /// The notification action id used for a meal quick-log button.
  static String mealActionId(String mealName) => 'meal:$mealName';

  /// Extracts the meal name from a [NotificationResponse.actionId], or `null`
  /// when the action was not a meal button.
  static String? mealNameFromActionId(String? actionId) {
    if (actionId == null || !actionId.startsWith('meal:')) return null;
    return actionId.substring('meal:'.length);
  }

  final FlutterLocalNotificationsPlugin _plugin;
  late final NotificationScheduler _scheduler;
  void Function(String? actionId, String? payload)? _onResponse;
  DailyLogRepository? _dailyLogRepository;
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
          _onResponse == null ? null : _handleResponse,
      onDidReceiveBackgroundNotificationResponse:
          onDidReceiveBackgroundNotificationResponse,
    );
    await _requestAndroidPermissions();
    _initialized = true;
  }

  /// Requests the Android runtime permissions the interactive reminders need:
  /// `POST_NOTIFICATIONS` (Android 13+) and exact-alarm scheduling.
  Future<void> _requestAndroidPermissions() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) return;
    await android.requestNotificationsPermission();
    await android.requestExactAlarmsPermission();
  }

  /// Replaces the notification-response handler (used when the service is
  /// created before the app owns a navigation controller).
  ///
  /// Receives both the action id (e.g. [exerciseYesActionId]) and the raw
  /// payload so the app can route exercise check-ins to the right surface.
  void setOnResponse(void Function(String? actionId, String? payload)? onResponse) {
    _onResponse = onResponse;
  }

  /// Replaces the meal-history repository used for the interactive action
  /// buttons (set once the app has built its repositories).
  void setDailyLogRepository(DailyLogRepository? repository) {
    _dailyLogRepository = repository;
  }

  void _handleResponse(NotificationResponse response) {
    _onResponse?.call(response.actionId, response.payload);
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

  /// Schedules the three interactive daily meal reminders (Breakfast 8 AM,
  /// Lunch 1 PM, Dinner 7 PM). Each reminder injects its top 3 meals for the
  /// slot as notification action buttons.
  Future<void> scheduleDailyMealReminders() async {
    await initialize();
    for (final slot in mealSlots) {
      await _scheduleMealReminder(slot);
    }
  }

  Future<void> _scheduleMealReminder(
    ({int id, String timeOfDay, String title, int hour, int minute}) slot,
  ) async {
    final meals = await _mealsFor(slot.timeOfDay);
    final scheduled = nextDailyOccurrence(
      tz.TZDateTime.now(tz.local),
      hour: slot.hour,
      minute: slot.minute,
    );
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _dailyChannelId,
        _dailyChannelName,
        channelDescription: _dailyChannelDescription,
        importance: Importance.high,
        priority: Priority.high,
        actions: [
          for (final meal in meals)
            AndroidNotificationAction(mealActionId(meal), meal),
        ],
      ),
      iOS: DarwinNotificationDetails(),
      macOS: DarwinNotificationDetails(),
    );
    await _scheduler.cancel(slot.id);
    await _scheduler.zonedSchedule(
      slot.id,
      slot.title,
      'Time for ${slot.title.toLowerCase()}',
      scheduled,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: slot.timeOfDay,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<List<String>> _mealsFor(String timeOfDay) async {
    final repo = _dailyLogRepository;
    if (repo == null) {
      return defaultMealsByTimeOfDay[timeOfDay] ?? const [];
    }
    return repo.getTopMealsForTimeOfDay(timeOfDay);
  }

  /// Builds the reactive body shown right after a meal is logged: a reminder
  /// when nothing has been trained today, otherwise a recovered-vs-burned
  /// summary based on the day's logged exercises.
  Future<String> mealLoggedNotificationBody({
    required DailyEntryRepository repository,
    required int recovered,
  }) async {
    final today = DailyEntry.dateKey(DateTime.now());
    final entry = await repository.getByDate(today);
    final exercises = entry?.exercises ?? const [];
    if (exercises.isEmpty) return 'Remember to do your routine!';
    // Prefer the persisted burn (from a check-in / in-app confirmation); fall
    // back to the flat estimate only when it was never recorded.
    final burned = (entry?.burned ?? 0) > 0
        ? entry!.burned
        : exercises.length * caloriesBurnedPerExercise;
    return "You've recovered $recovered of the $burned calories you burned!";
  }

  /// Shows an immediate "meal logged" notification with [body].
  Future<void> showMealLoggedNotification({required String body}) async {
    await initialize();
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
    await _plugin.show(mealLoggedNotificationId, 'Meal logged', body, details);
  }

  /// Reactive notification triggered right after logging a meal.
  ///
  /// Uses [repository] to check today's logged exercises and [recovered] as
  /// the calories consumed so far. Failures are swallowed so notification
  /// issues never break meal logging.
  Future<void> showReactiveMealNotification({
    required DailyEntryRepository repository,
    required int recovered,
  }) async {
    try {
      final body = await mealLoggedNotificationBody(
        repository: repository,
        recovered: recovered,
      );
      await showMealLoggedNotification(body: body);
    } catch (_) {
      // Notifications are non-critical.
    }
  }

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
