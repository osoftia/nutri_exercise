import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../data/meal_action_repository.dart';
import '../data/local_meal_action_repository.dart';
import '../data/local_tamagotchi_progress_repository.dart';
import '../data/tamagotchi_progress_repository.dart';
import '../models/daily_entry.dart';
import '../models/meal_action.dart';
import '../models/tamagotchi_progress.dart';
import '../state/muscle_tamagotchi_state.dart';
import 'notification_service.dart';

/// Default calorie estimate applied when a meal is quick-logged from a
/// notification action (the meal name alone carries no nutrition data).
const int defaultMealCalories = 500;

/// Background-isolate entry point for notification action responses.
///
/// Must be a top-level function annotated with `@pragma('vm:entry-point')` so
/// `flutter_local_notifications` can invoke it on a background isolate without
/// the app UI running.
@pragma('vm:entry-point')
Future<void> onDidReceiveBackgroundNotificationResponse(
  NotificationResponse response,
) {
  return handleNotificationResponse(response);
}

/// Processes a notification action response: writes the quick-logged meal to
/// SQLite, runs the tamagotchi bloat math against the persisted progress, and
/// clears the notification.
///
/// Repositories and the plugin are injectable for tests; production uses the
/// SQLite-backed implementations.
@visibleForTesting
Future<void> handleNotificationResponse(
  NotificationResponse response, {
  MealActionRepository? mealRepository,
  TamagotchiProgressRepository? progressRepository,
  FlutterLocalNotificationsPlugin? plugin,
}) async {
  final pluginInstance = plugin ?? FlutterLocalNotificationsPlugin();

  final meal = NotificationService.mealNameFromActionId(response.actionId);
  if (meal == null) {
    // A plain tap or a non-meal action: nothing to persist in the background.
    await _cancelNotification(pluginInstance, response);
    return;
  }

  final meals = mealRepository ?? LocalMealActionRepository();
  final progress = progressRepository ?? LocalTamagotchiProgressRepository();

  await meals.logMeal(
    MealAction(
      date: DailyEntry.dateKey(DateTime.now()),
      meal: meal,
      timeOfDay: response.payload ?? '',
    ),
  );

  final current = (await progress.get())?.coreFullness ?? 0.0;
  final updated = MuscleTamagotchiState.coreFullnessAfterNutrition(
    current,
    defaultMealCalories,
  );
  await progress.save(
    TamagotchiProgress(coreFullness: updated, updatedAt: DateTime.now()),
  );

  await _cancelNotification(pluginInstance, response);
}

Future<void> _cancelNotification(
  FlutterLocalNotificationsPlugin plugin,
  NotificationResponse response,
) async {
  final id = response.id;
  if (id == null) return;
  try {
    await plugin.cancel(id);
  } catch (_) {
    // The plugin may be unavailable on some platforms in the background
    // isolate; clearing the notification is best-effort.
  }
}