import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../constants/meal_presets.dart';
import '../data/daily_entry_repository.dart';
import '../data/daily_log_repository.dart';
import '../data/symptom_repository.dart';
import '../models/daily_entry.dart';
import '../utils/weekly_stats.dart';
import 'local_notification_scheduler.dart';
import 'notification_background_handler.dart';
import 'notification_config.dart';

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
///
/// Identifier constants live in [NotificationConfig]; the [NotificationDetails]
/// builders live in [NotificationDetailsFactory]. This class only orchestrates
/// initialization, scheduling and the reactive notifications.
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

  // --- Re-exported config constants (backwards-compatible API) -----------
  static const int dailyReminderId = NotificationConfig.dailyReminderId;
  static const int breakfastReminderId = NotificationConfig.breakfastReminderId;
  static const int lunchReminderId = NotificationConfig.lunchReminderId;
  static const int dinnerReminderId = NotificationConfig.dinnerReminderId;
  static const int mealLoggedNotificationId =
      NotificationConfig.mealLoggedNotificationId;
  static const int exerciseReminderId = NotificationConfig.exerciseReminderId;
  static const int exerciseReminderTestId =
      NotificationConfig.exerciseReminderTestId;
  static const String exerciseYesActionId =
      NotificationConfig.exerciseYesActionId;
  static const String exerciseNoActionId = NotificationConfig.exerciseNoActionId;
  static const int nightlyCheckInId = NotificationConfig.nightlyCheckInId;
  static const int nightlyCheckInTestId =
      NotificationConfig.nightlyCheckInTestId;
  static const String symptomCheckInActionId =
      NotificationConfig.symptomCheckInActionId;
  static const String activityCheckInActionId =
      NotificationConfig.activityCheckInActionId;
  static const int nightlyCheckInHour = NotificationConfig.nightlyCheckInHour;
  static const int nightlyCheckInMinute = NotificationConfig.nightlyCheckInMinute;
  static const String nightlyCheckInTitle = NotificationConfig.nightlyCheckInTitle;
  static const String nightlyCheckInBodyBoth =
      "You haven't logged your symptoms or activity today.";
  static const String nightlyCheckInBodySymptoms =
      "How are you feeling? Log today's symptoms.";
  static const String nightlyCheckInBodyActivity =
      "You haven't logged any activity today.";
  static const List<
    ({int id, String timeOfDay, String title, int hour, int minute})
  >
  mealSlots = NotificationConfig.mealSlots;

  /// The notification action id used for a meal quick-log button.
  static String mealActionId(String mealName) =>
      NotificationConfig.mealActionId(mealName);

  /// Extracts the meal name from a [NotificationResponse.actionId], or `null`
  /// when the action was not a meal button.
  static String? mealNameFromActionId(String? actionId) =>
      NotificationConfig.mealNameFromActionId(actionId);

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
  void setOnResponse(
    void Function(String? actionId, String? payload)? onResponse,
  ) {
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
    await _plugin.periodicallyShow(
      routineId,
      'Routine reminder',
      'Time for your Day $dayOfWeek workout',
      RepeatInterval.weekly,
      NotificationDetailsFactory.routine(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  /// Schedules the daily check-in reminder at [hour]:[minute] local time.
  ///
  /// Cancels any previous daily reminder first so relaunching never stacks
  /// duplicates.
  Future<void> scheduleDailyReminder({int hour = 20, int minute = 0}) async {
    await initialize();
    final scheduled = _nextAtOrAfter(hour: hour, minute: minute);
    await _scheduler.cancel(dailyReminderId);
    await _scheduler.zonedSchedule(
      dailyReminderId,
      NotificationConfig.dailyReminderTitle,
      NotificationConfig.dailyReminderBody,
      scheduled,
      NotificationDetailsFactory.daily(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Immediately shows a test exercise check-in notification (used by the
  /// "EXERCISE NOT" button).
  Future<void> showExerciseReminderTest({String? payload}) async {
    await initialize();
    await _plugin.show(
      exerciseReminderTestId,
      NotificationConfig.exerciseTitle,
      NotificationConfig.exerciseBody,
      NotificationDetailsFactory.exercise(),
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
    final scheduled = _nextAtOrAfter(hour: 21, minute: 0);
    await _scheduler.cancel(exerciseReminderId);
    await _scheduler.zonedSchedule(
      exerciseReminderId,
      NotificationConfig.exerciseTitle,
      NotificationConfig.exerciseBody,
      scheduled,
      NotificationDetailsFactory.exercise(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: payload,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Immediately shows a test nightly check-in notification (used by the
  /// quick-test triggers in the Profile settings sections).
  Future<void> showNightlyCheckInTest() async {
    await initialize();
    await _plugin.show(
      nightlyCheckInTestId,
      nightlyCheckInTitle,
      nightlyCheckInBodyBoth,
      NotificationDetailsFactory.nightly(nightlyCheckInBodyBoth),
    );
  }

  /// Builds the nightly check-in body from what is still missing.
  static String nightlyCheckInBody({
    required bool needsSymptoms,
    required bool needsActivity,
  }) {
    if (needsSymptoms && needsActivity) return nightlyCheckInBodyBoth;
    if (needsSymptoms) return nightlyCheckInBodySymptoms;
    return nightlyCheckInBodyActivity;
  }

  /// Schedules (or clears) the evening nightly check-in.
  ///
  /// Prompts only for logs that have not appeared yet: when both the day's
  /// symptoms and activity are already recorded, any existing check-in is
  /// cancelled instead of scheduled. The reminder carries icon actions that
  /// open the app on the matching surface.
  Future<void> scheduleNightlyCheckIn({
    required SymptomRepository symptomRepository,
    required DailyEntryRepository entryRepository,
  }) async {
    await initialize();
    final today = DailyEntry.dateKey(DateTime.now());

    final symptoms = await symptomRepository.getForDate(today);
    final needsSymptoms = symptoms.every((log) => log.level <= 0);

    final entry = await entryRepository.getByDate(today);
    final hasActivity =
        (entry?.exercises.isNotEmpty ?? false) || (entry?.calories ?? 0) > 0;
    final needsActivity = !hasActivity;

    await _scheduler.cancel(nightlyCheckInId);
    if (!needsSymptoms && !needsActivity) return;

    final scheduled = _nextAtOrAfter(
      hour: nightlyCheckInHour,
      minute: nightlyCheckInMinute,
    );
    final body = nightlyCheckInBody(
      needsSymptoms: needsSymptoms,
      needsActivity: needsActivity,
    );
    await _scheduler.zonedSchedule(
      nightlyCheckInId,
      nightlyCheckInTitle,
      body,
      scheduled,
      NotificationDetailsFactory.nightly(body),
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
    final scheduled = _nextAtOrAfter(hour: slot.hour, minute: slot.minute);
    await _scheduler.cancel(slot.id);
    await _scheduler.zonedSchedule(
      slot.id,
      slot.title,
      'Time for ${slot.title.toLowerCase()}',
      scheduled,
      NotificationDetailsFactory.meals(meals),
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
    await _plugin.show(
      mealLoggedNotificationId,
      'Meal logged',
      body,
      NotificationDetailsFactory.mealLogged(),
    );
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

  /// The next [hour]:[minute] wall-clock occurrence from now.
  tz.TZDateTime _nextAtOrAfter({required int hour, required int minute}) =>
      nextDailyOccurrence(
        tz.TZDateTime.now(tz.local),
        hour: hour,
        minute: minute,
      );

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
