import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Channel, id, action and copy constants shared by the notification service
/// and its detail builders.
///
/// Kept separate from [NotificationService] so the identifier contract can be
/// referenced (and tested) without pulling in the service implementation.
class NotificationConfig {
  NotificationConfig._();

  /// Weekly routine reminder channel.
  static const String channelId = 'routine_reminders';
  static const String channelName = 'Routine reminders';
  static const String channelDescription =
      'Weekly reminders for scheduled workouts';

  /// Daily check-in channel.
  static const String dailyChannelId = 'daily_log_reminders';
  static const String dailyChannelName = 'Daily check-in';
  static const String dailyChannelDescription =
      'A daily nudge to log what you ate and trained';
  static const String dailyReminderTitle = 'Daily check-in';
  static const String dailyReminderBody = 'What did you eat and train today?';

  /// Workout check-in channel.
  static const String exerciseChannelId = 'exercise_reminders';
  static const String exerciseChannelName = 'Workout check-in';
  static const String exerciseChannelDescription =
      'Asks if you completed your workout routines';
  static const String exerciseTitle = 'Workout check-in';
  static const String exerciseBody =
      'Did you complete your workout routines today?';

  /// Nightly check-in channel.
  static const String nightlyChannelId = 'nightly_check_ins';
  static const String nightlyChannelName = 'Nightly check-in';
  static const String nightlyChannelDescription =
      'Prompts for the daily symptom and activity logs';
  static const String nightlyCheckInTitle = 'Nightly check-in';

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

  /// Stable id for the evening nightly symptom + activity check-in.
  static const int nightlyCheckInId = 3301;

  /// Stable id for the "nightly check-in" quick-test notification.
  static const int nightlyCheckInTestId = 3302;

  /// Notification action ids for the nightly check-in.
  static const String symptomCheckInActionId = 'symptom_check_in';
  static const String activityCheckInActionId = 'activity_check_in';

  /// Evening hour/minute for the nightly check-in.
  static const int nightlyCheckInHour = 20;
  static const int nightlyCheckInMinute = 30;

  /// The interactive daily meal reminder slots.
  static const List<
    ({int id, String timeOfDay, String title, int hour, int minute})
  >
  mealSlots = [
    (
      id: breakfastReminderId,
      timeOfDay: 'breakfast',
      title: 'Breakfast',
      hour: 8,
      minute: 0,
    ),
    (
      id: lunchReminderId,
      timeOfDay: 'lunch',
      title: 'Lunch',
      hour: 13,
      minute: 0,
    ),
    (
      id: dinnerReminderId,
      timeOfDay: 'dinner',
      title: 'Dinner',
      hour: 19,
      minute: 0,
    ),
  ];

  /// The notification action id used for a meal quick-log button.
  static String mealActionId(String mealName) => 'meal:$mealName';

  /// Extracts the meal name from a [NotificationResponse.actionId], or `null`
  /// when the action was not a meal button.
  static String? mealNameFromActionId(String? actionId) {
    if (actionId == null || !actionId.startsWith('meal:')) return null;
    return actionId.substring('meal:'.length);
  }
}

/// Builds the [NotificationDetails] for each notification kind.
///
/// Pure functions of the config constants, so they carry no state and can be
/// asserted directly in tests.
class NotificationDetailsFactory {
  NotificationDetailsFactory._();

  /// Weekly routine reminder details.
  static NotificationDetails routine() => const NotificationDetails(
    android: AndroidNotificationDetails(
      NotificationConfig.channelId,
      NotificationConfig.channelName,
      channelDescription: NotificationConfig.channelDescription,
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
    macOS: DarwinNotificationDetails(),
  );

  /// Daily check-in reminder details.
  static NotificationDetails daily() => const NotificationDetails(
    android: AndroidNotificationDetails(
      NotificationConfig.dailyChannelId,
      NotificationConfig.dailyChannelName,
      channelDescription: NotificationConfig.dailyChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
    macOS: DarwinNotificationDetails(),
  );

  /// Exercise check-in details with Yes / Not-yet actions.
  static NotificationDetails exercise() => const NotificationDetails(
    android: AndroidNotificationDetails(
      NotificationConfig.exerciseChannelId,
      NotificationConfig.exerciseChannelName,
      channelDescription: NotificationConfig.exerciseChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
      actions: [
        AndroidNotificationAction(
          NotificationConfig.exerciseYesActionId,
          'Yes',
          showsUserInterface: false,
        ),
        AndroidNotificationAction(
          NotificationConfig.exerciseNoActionId,
          'Not yet',
          showsUserInterface: false,
        ),
      ],
    ),
    iOS: DarwinNotificationDetails(),
    macOS: DarwinNotificationDetails(),
  );

  /// Nightly check-in details with icon actions and a big-text body.
  static NotificationDetails nightly(String body) => NotificationDetails(
    android: AndroidNotificationDetails(
      NotificationConfig.nightlyChannelId,
      NotificationConfig.nightlyChannelName,
      channelDescription: NotificationConfig.nightlyChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
      category: AndroidNotificationCategory.reminder,
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: NotificationConfig.nightlyCheckInTitle,
      ),
      actions: const [
        AndroidNotificationAction(
          NotificationConfig.symptomCheckInActionId,
          'Log symptoms',
          icon: DrawableResourceAndroidBitmap('ic_checkin_symptom'),
          showsUserInterface: true,
          cancelNotification: false,
        ),
        AndroidNotificationAction(
          NotificationConfig.activityCheckInActionId,
          'Log activity',
          icon: DrawableResourceAndroidBitmap('ic_checkin_activity'),
          showsUserInterface: true,
          cancelNotification: false,
        ),
      ],
    ),
    iOS: DarwinNotificationDetails(),
    macOS: DarwinNotificationDetails(),
  );

  /// Meal reminder details carrying one action per [meals] quick-log button.
  static NotificationDetails meals(List<String> meals) => NotificationDetails(
    android: AndroidNotificationDetails(
      NotificationConfig.dailyChannelId,
      NotificationConfig.dailyChannelName,
      channelDescription: NotificationConfig.dailyChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
      actions: [
        for (final meal in meals)
          AndroidNotificationAction(
            NotificationConfig.mealActionId(meal),
            meal,
          ),
      ],
    ),
    iOS: DarwinNotificationDetails(),
    macOS: DarwinNotificationDetails(),
  );

  /// Meal-logged reactive notification details.
  static NotificationDetails mealLogged() => const NotificationDetails(
    android: AndroidNotificationDetails(
      NotificationConfig.dailyChannelId,
      NotificationConfig.dailyChannelName,
      channelDescription: NotificationConfig.dailyChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
    macOS: DarwinNotificationDetails(),
  );
}
