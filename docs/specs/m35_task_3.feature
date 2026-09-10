# M35 Task 3 — State Re-render Trigger Verification

## Goal
Prove `HomePage` listens directly to `MuscleTamagotchiState` so the
avatar updates instantly without a manual page refresh.

## Findings
- M34 Task 1 already wrapped `MuscleGroupVisualizer` in
  `ListenableBuilder(listenable: _tamagotchi)` in
  `HomePage._buildDashboard`; every state mutation notifies.
- Missing: an end-to-end regression test pinning the instant re-render.

## Change
- Code: no production change needed (binding already in place); this
  task verifies it.
- New test `test/features/m35_task3_rerender_widget_test.dart`: pumps the
  real `HomePage`, records the body-map painter `revision`, taps
  `Quick Add` (food log → `applyMeal` → `notifyListeners`), pumps once,
  and asserts the revision increased and the daily totals updated — i.e.
  the avatar re-rendered from the state event alone, with no page refresh.

## Verify
- `fvm flutter test` new test + full suite; `dart analyze` touched files.
