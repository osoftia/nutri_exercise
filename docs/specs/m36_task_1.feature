# M36 Task 1 — Single Source of Truth for State

## Goal
`HomePage` must use one shared `MuscleTamagotchiState` instance (global /
inherited), never a per-widget duplicate or dummy/mock, so Quick Add and
exercise taps mutate the exact instance the avatar paints.

## Findings
- `HomePage` owns `final _tamagotchi = MuscleTamagotchiState()` + disposes it:
  every `HomePage` rebuild/re-mount gets an isolated copy; share card and
  body map only agree by accident (same field forwarded twice).
- No `Provider`/`InheritedWidget` binding exists; `InteractiveBodyMap` takes
  the state as a plain nullable param, so a null/forgotten param silently
  renders neutral colors with no growth.
- `MockTamagotchiProgressRepository` is persistence-only (progress model),
  not a state duplicate — no removal needed, just documented.

## Change
- `lib/core/state/muscle_tamagotchi_state.dart`: add global singleton
  `sharedMuscleTamagotchiState` + `resetSharedMuscleTamagotchiState()` (tests).
- `lib/ui/pages/home_page.dart`: accept optional `tamagotchiState` ctor param;
  resolve `widget.tamagotchiState ?? sharedMuscleTamagotchiState` via one
  `tamagotchi` getter; stop disposing the shared instance; all handlers
  (`_quickAdd`, `_simulateMeal`, `_simulateCoreWorkout`, exercise `onLog`,
  share card, `ListenableBuilder`, `MuscleGroupVisualizer`) use the getter.
- Audit: grep confirms no `MuscleTamagotchiState()` construction remains in
  `home_page.dart`; no dummy/mock state is referenced there.

## Verify
- `flutter analyze` clean on touched files.
- `flutter test` new `test/features/m36_task1_single_source_widget_test.dart`
  (identity: painter state == injected/global; shared mutation re-renders)
  + full suite green.
