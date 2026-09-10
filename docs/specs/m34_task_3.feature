# M34 Task 3 — Exercise Response State Synchronization

## Goal
The 9 PM "Yes" check-in must grow muscle tiers and shrink bloat in the
live avatar (UI) at the same time it persists slimming + burned calories
to SQLite.

## Findings
- `ExerciseResponseHandler.handleExerciseResponse` persists slimmed
  `coreFullness` + `burned` calories, but never touches
  `MuscleTamagotchiState`: no `applyGrowth` (tiers never grow from "Yes")
  and no `applySlimming` on the live avatar (UI keeps stale bloat).
- `handleNotificationResponse` (background isolate) has no live avatar by
  design — SQLite remains the source of truth there; the foreground
  caller can pass its avatar in.

## Change
- Add pure helper `growthGroupsFor(exercises)`: exercise names →
  `ExerciseMuscleMapper` activations → region ids →
  `tamagotchiGroupForRegion` → set of `MuscleTamagotchiGroup`.
- `handleExerciseResponse` gains optional `MuscleTamagotchiState? tamagotchi`:
  on "Yes" it calls `tamagotchi.applyGrowth(groups)` (empty → skip) and
  `tamagotchi.applySlimming(amount: slimmingPerExercise * n)` mirroring
  the persisted `slimmedFullness` math. Both notify → Task 1 rebuild.
  SQLite writes unchanged; existing calls without `tamagotchi` behave as
  before (backward compatible).
- Extend `exercise_response_handler_test.dart` with avatar-sync cases.

## Verify
- `fvm flutter test test/services/exercise_response_handler_test.dart`
  + related suites; full suite in Task 4.
