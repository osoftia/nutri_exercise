# Milestone 15 — Long-Term Body Projection & SQLite Planning

> **Author:** @Architect
> **Status:** Ready for @Coder implementation (strict TDD)
> **Branch:** `feature/m15-body-projection`
> **Contract:** `mobile_app/test/features/m15_projection.feature`

## 1. Scope

Add a projection engine to the **ROUTINES** tab:

1. **SQLite schema** for a 6-month recommended routine plan with milestones at
   1, 3 and 6 months (`projection_plan` + `projection_milestone`).
2. **Projection engine** — a pure function that turns (start weight, goal) into
   milestone rows with projected weight, shoulder factor, waist factor and a
   phase focus.
3. **Neumorphic timeline** — a segmented selector (`Now`, `1m`, `3m`, `6m`).
4. **Advanced dynamic avatar** — extends the M14 silhouette painter to morph
   shoulders and waist independently, animating smoothly when a milestone is
   selected.

## 2. SQLite schema

```sql
CREATE TABLE projection_plan (
  id INTEGER PRIMARY KEY CHECK (id = 1),
  start_weight_kg REAL NOT NULL,
  goal TEXT NOT NULL
);

CREATE TABLE projection_milestone (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  plan_id INTEGER NOT NULL,
  month INTEGER NOT NULL,
  weight_kg REAL NOT NULL,
  shoulder_factor REAL NOT NULL,   -- 0..1 (0 narrow, 0.5 baseline, 1 broad)
  waist_factor REAL NOT NULL,      -- 0..1 (0 slim, 0.5 baseline, 1 wide)
  focus TEXT NOT NULL
);
```

`DatabaseHelper` version is bumped to 2 with an `onUpgrade` that creates the
projection tables for existing installs.

## 3. Projection engine

`generateProjectionPlan({double startWeightKg, FitnessGoal goal})` returns a
`ProjectionPlan` with four milestones (month `0` baseline plus `1`, `3`, `6`).
Per-goal deltas (deterministic):

| goal | months | shoulderFactor | waistFactor | weight delta |
|------|--------|----------------|-------------|--------------|
| muscleGain | 1/3/6 | .60/.75/1.00 | .47/.44/.40 | +1.5/+3.5/+6.0 kg |
| fatLoss    | 1/3/6 | .50/.52/.55 | .42/.34/.25 | −1.5/−4.0/−7.0 kg |
| maintain   | 1/3/6 | .50/.50/.50 | .50/.49/.48 | 0/0/0 kg |
| endurance  | 1/3/6 | .52/.55/.58 | .48/.46/.44 | −0.5/−1.5/−3.0 kg |

## 4. Avatar morphing logic

The M14 `DynamicAvatarPainter` maps a single `morph` scalar. M15 introduces
`ProjectionAvatarPainter(shoulderFactor, waistFactor)` that decouples the two
dimensions:

```
shoulderHalfWidth = lerp(0.14, 0.26, shoulderFactor) * unit
waistHalfWidth    = lerp(0.08, 0.24, waistFactor)    * unit
```

- **Muscle gain** raises `shoulderFactor` (broader) while `waistFactor` dips.
- **Fat loss** lowers `waistFactor` (slimmer) while shoulders stay near baseline.

The `ProjectionAvatar` widget wraps the painter in nested `TweenAnimationBuilder`
(500 ms) so selecting a milestone smoothly retargets both factors.

## 5. Components

- `lib/core/models/projection_models.dart` — `ProjectionMilestone`,
  `ProjectionPlan`, `generateProjectionPlan`.
- `lib/core/data/projection_repository.dart` — abstract `ProjectionRepository`.
- `lib/core/data/local_projection_repository.dart` — SQLite-backed, seeds a
  generated plan when empty.
- `lib/core/mocks/mock_projection_repository.dart` — deterministic in-memory.
- `lib/core/state/projection_controller.dart` — `ChangeNotifier` (load, selected
  month, derived `shoulderFactor`/`waistFactor`).
- `lib/ui/atoms/projection_avatar.dart` — painter + animated widget.
- `lib/ui/atoms/neumorphic_timeline.dart` — segmented selector.
- `lib/ui/pages/routines_page.dart` — rewritten to host the projection section
  above the existing routine list.
- `main_shell_page.dart` / `app.dart` — inject `ProjectionController`.

## 6. Testability

- Engine is pure and unit-tested for all four goals and boundary factors.
- `LocalProjectionRepository` is tested against an in-memory `sqflite_common_ffi`
  database (same pattern as `local_profile_repository_test.dart`).
- Timeline segments are keyed `timeline_<month>`; avatar keyed
  `projection_avatar`; summary keyed `projection_summary`.
- Controller factor getters are the single source of truth; widget tests assert
  painter factors after `pumpAndSettle`.
