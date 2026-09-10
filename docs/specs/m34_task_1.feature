# M34 Task 1 — State Binding & Rebuild Trigger

## Goal
Guarantee every avatar-mutating event (log exercise, 9 PM "Yes",
quick-add food) calls `notifyListeners()` and forces the HomePage
avatar subtree to rebuild with the latest state.

## Findings
- `MuscleTamagotchiState.applyGrowth/applySlimming/applyMeal/applyNutrition/
  settleCore/setOverrides/clearOverrides/applyDecay` already call
  `notifyListeners()` — no missing call.
- `DailyNutritionState.add/reset` already notify.
- Gap: `HomePage` passes the raw `_tamagotchi` instance into
  `MuscleGroupVisualizer` (stateless, only watches `RoutineProvider`).
  Rebuild of the avatar relies solely on `InteractiveBodyMap`'s internal
  listener. If the widget is rebuilt for other reasons the binding holds,
  but there is no explicit avatar-subtree rebuild trigger at the HomePage
  level, and the legend row never listens to tamagotchi tiers.

## Change
- Wrap the `MuscleGroupVisualizer` in `HomePage._buildDashboard` with a
  `ListenableBuilder(listenable: _tamagotchi)` so every `notifyListeners()`
  rebuilds the avatar + legend subtree explicitly.
- Add doc comments on the event entry points (`_quickAdd`, `_simulateMeal`,
  `_simulateCoreWorkout`, exercise `onLog`) noting the notify→rebuild chain.

## Verify
- `flutter analyze`
- `flutter test` (full suite, zero regressions)
