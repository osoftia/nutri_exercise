import '../data/daily_entry_repository.dart';
import '../data/tamagotchi_progress_repository.dart';
import '../models/daily_entry.dart';
import '../models/tamagotchi_progress.dart';
import '../state/muscle_tamagotchi_state.dart';
import '../utils/weekly_stats.dart';
import 'notification_service.dart';

/// Handles the 9 PM exercise check-in response and calculates the workout
/// calorie burn, applying the tamagotchi slimming math and updating the
/// SQLite daily log.
class ExerciseResponseHandler {
  const ExerciseResponseHandler._();

  /// Total calories burned for [exercises] (250 kcal each).
  static int caloriesBurnedFor(List<String> exercises) =>
      exercises.length * caloriesBurnedPerExercise;

  /// The core fullness after slimming by one unit per [exercises].
  static double slimmedFullness(double current, List<String> exercises) =>
      MuscleTamagotchiState.coreFullnessAfterSlimming(
        current,
        amount: MuscleTamagotchiState.slimmingPerExercise * exercises.length,
      );

  /// Processes a check-in response.
  ///
  /// When [actionId] is the "Yes" action, today's logged exercises determine
  /// the burned calories which are stored on today's entry, and the tamagotchi
  /// core fullness is reduced (slimming). "Not yet" and other actions are a
  /// no-op.
  static Future<void> handleExerciseResponse({
    required String? actionId,
    required DailyEntryRepository entries,
    required TamagotchiProgressRepository progress,
  }) async {
    if (actionId != NotificationService.exerciseYesActionId) return;

    final today = DailyEntry.dateKey(DateTime.now());
    final entry = await entries.getByDate(today);
    final exercises = entry?.exercises ?? const <String>[];
    final burned = caloriesBurnedFor(exercises);

    final current = (await progress.get())?.coreFullness ?? 0.0;
    final slimmed = slimmedFullness(current, exercises);
    await progress.save(
      TamagotchiProgress(coreFullness: slimmed, updatedAt: DateTime.now()),
    );

    await entries.save(
      (entry ?? DailyEntry(date: today)).copyWith(burned: burned),
    );
  }
}