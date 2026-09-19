import 'dart:async';

import 'package:flutter/material.dart';

import '../data/tamagotchi_progress_repository.dart';
import '../models/log_parse_response.dart';
import '../models/tamagotchi_progress.dart';

/// The four gamified muscle groups of the tamagotchi avatar.
enum MuscleTamagotchiGroup { core, arms, chest, legs }

/// Tier derived from a group's mass, used for heatmap colouring.
enum MuscleTier { c, b, a, s }

/// Owns the tamagotchi avatar's muscle mass, growth and decay.
///
/// Each group holds a normalised [0.0, 1.0] mass value. Completing a routine
/// [applyGrowth]s the targeted groups; time passing without training
/// [applyDecay]s every group.
class MuscleTamagotchiState extends ChangeNotifier {
  MuscleTamagotchiState({
    Map<MuscleTamagotchiGroup, double> initialMass = const {},
    this.growthDelta = 0.08,
    this.decayPerDay = 0.05,
    TamagotchiProgressRepository? repository,
  }) : _repository = repository {
    for (final group in MuscleTamagotchiGroup.values) {
      _mass[group] = (initialMass[group] ?? baseline).clamp(0.0, 1.0);
    }
  }

  /// Optional SQLite-backed store. When attached, every mutation is persisted
  /// and [restore] rehydrates the avatar after an app restart.
  TamagotchiProgressRepository? _repository;

  /// Attaches (or clears) the persistence store used by [restore]/[toProgress].
  void attachRepository(TamagotchiProgressRepository? repository) {
    _repository = repository;
  }

  /// Neutral starting mass for every group.
  static const double baseline = 0.5;

  /// Mass gained per completed routine targeting the group.
  final double growthDelta;

  /// Mass lost per full day of inactivity.
  final double decayPerDay;

  final Map<MuscleTamagotchiGroup, double> _mass = {};

  double _coreFullness = 0.0;
  bool _coreBloating = false;

  /// Number of food logs submitted through [applyMeal]/[applyNutrition].
  /// The body map watches this to flash the stomach on every meal.
  int _mealCount = 0;

  /// Wall-clock time of the most recent food log, if any.
  DateTime? _lastMealAt;

  /// How long the stomach red-flash debug effect lasts after a food log.
  static const Duration foodFlashDuration = Duration(seconds: 2);

  /// Number of food logs submitted so far.
  int get mealCount => _mealCount;

  /// Wall-clock time of the most recent food log, if any.
  DateTime? get lastMealAt => _lastMealAt;

  /// Whether a food flash started at [lastMealAt] is still active at [now].
  static bool foodFlashActiveSince(DateTime? lastMealAt, DateTime now) {
    if (lastMealAt == null) return false;
    return now.difference(lastMealAt) < foodFlashDuration;
  }

  /// Per-region color overrides keyed by region id (e.g. `chest`).
  /// Applied by the body map before falling back to tier colors.
  Map<String, Color> regionColorOverrides = {};

  /// Replaces the active color overrides and notifies listeners.
  void setOverrides(Map<String, Color> overrides) {
    regionColorOverrides = Map<String, Color>.from(overrides);
    notifyListeners();
  }

  /// Clears all color overrides and notifies listeners.
  void clearOverrides() {
    if (regionColorOverrides.isEmpty) return;
    regionColorOverrides = {};
    notifyListeners();
  }

  /// Current mass of [group], always within `[0.0, 1.0]`.
  double massOf(MuscleTamagotchiGroup group) => _mass[group] ?? baseline;

  /// Calories-driven core fullness (`0..1`), raised each time nutrition is
  /// logged and clipped at `1.0`. Drives the permanent (settled) core scale.
  double get coreFullness => _coreFullness;

  /// Whether the core is currently mid-bloat (transient) after eating.
  bool get coreIsBloating => _coreBloating;

  /// Snapshots the persisted subset of this state (mass + core fullness).
  TamagotchiProgress toProgress() => TamagotchiProgress(
        coreFullness: _coreFullness,
        mass: {
          for (final group in MuscleTamagotchiGroup.values)
            group.name: _mass[group] ?? baseline,
        },
        updatedAt: DateTime.now(),
      );

  /// Loads the persisted masses and core fullness and notifies listeners.
  ///
  /// A no-op when no repository is attached or nothing has been stored yet, so
  /// fresh installs keep their neutral baseline.
  Future<void> restore() async {
    final repository = _repository;
    if (repository == null) return;
    final progress = await repository.get();
    if (progress == null) return;

    for (final group in MuscleTamagotchiGroup.values) {
      final stored = progress.mass[group.name];
      if (stored != null) _mass[group] = stored.clamp(0.0, 1.0);
    }
    _coreFullness = progress.coreFullness.clamp(0.0, 1.0);
    notifyListeners();
  }

  /// Fire-and-forget persistence of [toProgress] to the attached repository.
  void _persist() {
    final repository = _repository;
    if (repository == null) return;
    unawaited(repository.save(toProgress()));
  }

  /// Fires the "just ate" reaction: temporarily bloats the core and raises its
  /// permanent fullness in proportion to [calories].
  void applyNutrition(int calories) {
    _coreFullness = coreFullnessAfterNutrition(_coreFullness, calories);
    _coreBloating = true;
    _mealCount++;
    _lastMealAt = DateTime.now();
    _persist();
    notifyListeners();
  }

  /// Applies a meal to the avatar based on its food quality: healthy meals
  /// (high protein / vegetables) grow the arms, legs and chest muscle vectors,
  /// while unhealthy meals increase stomach bloat.
  void applyMeal(LogParseResponse meal) {
    _mealCount++;
    _lastMealAt = DateTime.now();
    if (meal.isHealthy) {
      applyGrowth(const [
        MuscleTamagotchiGroup.arms,
        MuscleTamagotchiGroup.legs,
        MuscleTamagotchiGroup.chest,
      ]);
    } else {
      applyNutrition(meal.calories);
    }
  }

  /// Ends the transient bloat; the increased fullness (permanent size) remains.
  void settleCore() {
    if (!_coreBloating) return;
    _coreBloating = false;
    notifyListeners();
  }

  /// Slimming applied to [coreFullness] per logged exercise.
  static const double slimmingPerExercise = 0.15;

  /// Pure, background-isolate-safe bloat math: returns the core fullness after
  /// consuming [calories], clipped to `[0.0, 1.0]`.
  static double coreFullnessAfterNutrition(double current, int calories) =>
      (current + calories / 2000).clamp(0.0, 1.0);

  /// Pure, background-isolate-safe slimming math: returns the core fullness
  /// after training, clipped to `[0.0, 1.0]`.
  static double coreFullnessAfterSlimming(
    double current, {
    double amount = slimmingPerExercise,
  }) =>
      (current - amount).clamp(0.0, 1.0);

  /// Applies the "slimming" effect of logging an exercise: reduces the
  /// permanent core fullness (and clears any transient bloat), so the core's
  /// settled scale/width shrinks, counteracting the expansion from eating.
  ///
  /// [amount] defaults to [slimmingPerExercise] and is clipped to keep
  /// [coreFullness] within `[0.0, 1.0]`.
  void applySlimming({double amount = slimmingPerExercise}) {
    _coreFullness = coreFullnessAfterSlimming(_coreFullness, amount: amount);
    _coreBloating = false;
    _persist();
    notifyListeners();
  }

  /// The permanent core scale derived from [coreFullness] (never below `1.0`).
  double settledCoreScale() => 1.0 + 0.4 * _coreFullness;

  /// Tier derived from [group]'s mass.
  MuscleTier tierOf(MuscleTamagotchiGroup group) {
    final mass = massOf(group);
    if (mass >= 0.9) return MuscleTier.s;
    if (mass >= 0.66) return MuscleTier.a;
    if (mass >= 0.33) return MuscleTier.b;
    return MuscleTier.c;
  }

  /// Grows the given groups by [growthDelta], clamped at `1.0`.
  void applyGrowth(Iterable<MuscleTamagotchiGroup> groups) {
    for (final group in groups) {
      _mass[group] = (_mass[group] ?? baseline).clamp(0.0, 1.0);
      _mass[group] = (_mass[group]! + growthDelta).clamp(0.0, 1.0);
    }
    _persist();
    notifyListeners();
  }

  /// Shrinks the given groups by [growthDelta], clamped at `0.0`.
  ///
  /// Used to reverse a workout confirmation when the user unchecks it.
  void applyShrink(Iterable<MuscleTamagotchiGroup> groups) {
    for (final group in groups) {
      _mass[group] =
          ((_mass[group] ?? baseline) - growthDelta).clamp(0.0, 1.0);
    }
    _persist();
    notifyListeners();
  }

  /// Adds [amount] back to the permanent core fullness and clears transient
  /// bloat, reversing a prior slimming.
  void restoreCore(double amount) {
    _coreFullness = (_coreFullness + amount).clamp(0.0, 1.0);
    _coreBloating = false;
    _persist();
    notifyListeners();
  }

  /// Decays every group by [decayPerDay] scaled to [elapsed], clamped at `0.0`.
  void applyDecay(Duration elapsed) {
    final days = elapsed.inMilliseconds / Duration.millisecondsPerDay;
    final amount = decayPerDay * days;
    for (final group in MuscleTamagotchiGroup.values) {
      _mass[group] = ((_mass[group] ?? baseline) - amount).clamp(0.0, 1.0);
    }
    _persist();
    notifyListeners();
  }
}

/// M36 Task 1: single source of truth for the Tamagotchi avatar.
///
/// `HomePage` (and every widget under it) must observe this exact instance
/// unless a test injects its own via `HomePage(tamagotchiState: ...)`.
/// A per-widget `MuscleTamagotchiState()` duplicate silently forks growth /
/// bloat state so taps stop moving the painted avatar.
MuscleTamagotchiState sharedMuscleTamagotchiState = MuscleTamagotchiState();

/// Replaces the shared instance with a fresh baseline (tests only), so
/// widget tests stay isolated from each other.
void resetSharedMuscleTamagotchiState() {
  sharedMuscleTamagotchiState = MuscleTamagotchiState();
}
