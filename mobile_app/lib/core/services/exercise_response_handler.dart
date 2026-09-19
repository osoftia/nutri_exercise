import '../constants/tamagotchi_groups.dart';
import '../data/body_detail_repository.dart';
import '../data/daily_entry_repository.dart';
import '../data/tamagotchi_progress_repository.dart';
import '../domain/notifications/exercise_check_in.dart';
import '../models/daily_entry.dart';
import '../models/tamagotchi_progress.dart';
import '../state/muscle_tamagotchi_state.dart';
import '../utils/exercise_muscle_mapper.dart';
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

  /// The tamagotchi muscle groups targeted by [exercises].
  ///
  /// Each exercise name resolves through [ExerciseMuscleMapper] to its
  /// primary/secondary region ids, which map back to tamagotchi groups.
  /// Unknown exercises contribute no groups.
  static Set<MuscleTamagotchiGroup> growthGroupsFor(
    List<String> exercises,
  ) {
    final groups = <MuscleTamagotchiGroup>{};
    for (final name in exercises) {
      final activation = ExerciseMuscleMapper.activationFor(name);
      for (final regionId in [
        ...activation.primaryRegions,
        ...activation.secondaryRegions,
      ]) {
        final group = tamagotchiGroupForRegion(regionId);
        if (group != null) groups.add(group);
      }
    }
    return groups;
  }

  /// Processes a check-in response.
  ///
  /// When [actionId] is the "Yes" action, today's logged exercises determine
  /// the burned calories which are stored on today's entry, and the tamagotchi
  /// core fullness is reduced (slimming). "Not yet" and other actions are a
  /// no-op.
  ///
  /// When [tamagotchi] (the live foreground avatar) is provided, the same
  /// event also mutates it — growing the targeted muscle tiers and shrinking
  /// its bloat with the same slimming math persisted to SQLite — so the UI
  /// rebuilds simultaneously via `notifyListeners()`. Background-isolate
  /// callers omit it (no live UI there); SQLite stays the source of truth.
  static Future<void> handleExerciseResponse({
    required String? actionId,
    required DailyEntryRepository entries,
    required TamagotchiProgressRepository progress,
    String? payload,
    MuscleTamagotchiState? tamagotchi,
    BodyDetailRepository? completions,
  }) async {
    if (actionId != NotificationService.exerciseYesActionId) return;

    final today = DailyEntry.dateKey(DateTime.now());
    final entry = await entries.getByDate(today);
    final names = entry?.exercises ?? const <String>[];

    // Prefer the structured payload (sets/reps/load); fall back to the stored
    // exercise names when the notification carried none.
    final checkIn = ExerciseCheckIn.tryParse(payload);
    final structured =
        (checkIn != null && checkIn.exercises.isNotEmpty) ? checkIn.exercises : null;
    final completed =
        structured ?? ExerciseCheckIn.fromNames(names).exercises;
    final burnedNames = completed.map((exercise) => exercise.name).toList();
    final burned = caloriesBurnedFor(burnedNames);

    final current = (await progress.get())?.coreFullness ?? 0.0;
    final slimmed = slimmedFullness(current, burnedNames);
    await progress.save(
      TamagotchiProgress(coreFullness: slimmed, updatedAt: DateTime.now()),
    );

    await entries.save(
      (entry ?? DailyEntry(date: today)).copyWith(burned: burned),
    );

    // Persist the day's completed exercises so the foreground popup can present
    // them after a notification action.
    if (completions != null && completed.isNotEmpty) {
      await completions.saveCompletedExercises(completed);
    }

    final avatar = tamagotchi;
    if (avatar != null) {
      final groups = growthGroupsFor(burnedNames);
      if (groups.isNotEmpty) avatar.applyGrowth(groups);
      avatar.applySlimming(
        amount: MuscleTamagotchiState.slimmingPerExercise * burnedNames.length,
      );
    }
  }
}