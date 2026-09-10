# M35 Task 1 — Stomach Red Flash Debug

## Goal
Whenever a food log is submitted, the stomach (`abs`) region flashes
bright red for 2 seconds, proving bloat state and UI re-render communicate.

## Findings
- `MuscleTamagotchiState.applyMeal/applyNutrition` already notify, and the
  map already tints core red *while bloating* — but healthy meals never
  bloat, and the 700 ms bloat overshoot is subtle. There is no explicit,
  uniform "food was logged" visual signal.
- No meal counter / timestamp exists on the state, so the widget cannot
  distinguish a food event from other mutations.

## Change
- `MuscleTamagotchiState`: add `mealCount` (incremented by `applyMeal`
  and `applyNutrition`), `lastMealAt`, `foodFlashDuration = 2 s`, and pure
  helper `foodFlashActiveSince(lastMealAt, now)` for testability.
- `InteractiveBodyMap`: track last seen `mealCount`; on increase, set a
  2 s flash window (restartable `Timer`, cancelled on dispose/supersede)
  and pass `foodFlash` to `_BodyMapPainter`; painter paints `abs` bright
  red (`Colors.red`) while flashing and includes the flag in
  `shouldRepaint`.
- Tests: state unit tests (counter, active/expired flash math) + widget
  test (flash turns on after `applyMeal`, off after 2 s of pumped time).

## Verify
- `dart analyze` on touched files; `fvm flutter test` subset + full in Task 3.
