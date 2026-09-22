import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../data/daily_entry_repository.dart';
import '../data/body_detail_repository.dart';
import '../data/local_body_detail_repository.dart';
import '../data/local_daily_entry_repository.dart';
import '../data/meal_action_repository.dart';
import '../data/local_meal_action_repository.dart';
import '../data/local_tamagotchi_progress_repository.dart';
import '../data/tamagotchi_progress_repository.dart';
import '../models/daily_entry.dart';
import '../models/meal_action.dart';
import '../models/tamagotchi_progress.dart';
import '../state/muscle_tamagotchi_state.dart';
import 'exercise_response_handler.dart';
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
/// clears the notification. Exercise check-in responses ("Yes"/"Not yet") are
/// dispatched to [ExerciseResponseHandler].
///
/// Repositories and the plugin are injectable for tests; production uses the
/// SQLite-backed implementations.
@visibleForTesting
Future<void> handleNotificationResponse(
  NotificationResponse response, {
  MealActionRepository? mealRepository,
  TamagotchiProgressRepository? progressRepository,
  DailyEntryRepository? dailyEntryRepository,
  BodyDetailRepository? bodyDetailRepository,
  FlutterLocalNotificationsPlugin? plugin,
}) async {
  final pluginInstance = plugin ?? FlutterLocalNotificationsPlugin();
  final actionId = response.actionId;

  if (actionId == NotificationService.exerciseYesActionId ||
      actionId == NotificationService.exerciseNoActionId) {
    await ExerciseResponseHandler.handleExerciseResponse(
      actionId: actionId,
      entries: dailyEntryRepository ?? LocalDailyEntryRepository(),
      progress: progressRepository ?? LocalTamagotchiProgressRepository(),
      payload: response.payload,
      completions: actionId == NotificationService.exerciseYesActionId
          ? bodyDetailRepository ?? LocalBodyDetailRepository()
          : null,
    );
    await _cancelNotification(pluginInstance, response);
    return;
  }

  if (actionId == NotificationService.symptomCheckInActionId ||
      actionId == NotificationService.activityCheckInActionId) {
    // These actions open the app on the matching surface, so there is nothing
    // to persist here; just clear the check-in.
    await _cancelNotification(pluginInstance, response);
    return;
  }

  final meal = NotificationService.mealNameFromActionId(actionId);
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

  final persisted = await progress.get();
  final current = persisted?.coreFullness ?? 0.0;
  final updated = MuscleTamagotchiState.coreFullnessAfterNutrition(
    current,
    defaultMealCalories,
  );
  await progress.save(
    TamagotchiProgress(
      coreFullness: updated,
      mass: persisted?.mass ?? const {},
      updatedAt: DateTime.now(),
    ),
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