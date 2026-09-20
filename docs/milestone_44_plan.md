# Milestone 44 Plan — Avatar Restoration, Green Stomach Semantics, Grid & History Data

## Git branch
`feature/m44-adjustments` (delivered as per-task commits on `main`, mirroring the
M41–M43 autonomous sprint convention).

## Goal
Polish the unified body experience: restore an organic silhouette, give healthy
protein surpluses a green stomach, add the engineering grid backdrop, and repair
the weekly/calendar data providers.

## Gherkin contract
`mobile_app/test/features/m44_adjustments.feature`

## Task breakdown
1. **Restore & Harmonize Nutrition Avatar**
   - `BodySegmentGeometry._torso` now draws soft, convex side curves (quadratic
     Béziers bulging to the wider baseline half-width) instead of straight
     trapezoid sides, while keeping the articulated elbow/knee joint gaps.
   - Bounds and hit tests are unchanged, so both tabs share the exact silhouette.
   - Golden `body_blueprint_painter.png` regenerated.

2. **Protein & Health Green Stomach Semantics**
   - `SegmentStatus.healthy` added; `BodySegmentPalette` maps it to `#10B981`.
   - `SegmentBalanceCalculator.isHealthySurplus` marks a calorie surplus as
     healthy only when protein is at/above target and its delta is >= the carb and
     fat deltas; carb/fat-led surpluses keep amber/red.

3. **Blueprint Technical Grid Background**
   - New `BlueprintGridPainter` (lattice, brighter majors every 4 cells, centre
     crosshair).
   - `BodyBlueprintDiagram`/`UnifiedBodyBlueprint` gain `showGrid` (default true),
     so both tabs render it behind the figure.

4. **Fix Weekly States & Calendar Data Views**
   - `computeWeeklyStats` uses the persisted `DailyEntry.burned` when present
     (fallback: 250 kcal/exercise).
   - `WorkoutCompletionController` optionally upserts/clears today's `DailyEntry`
     (exercise names + burned) on confirm/undo, preserving nutrition.
   - `app.dart` caches and shares one `DailyEntryRepository` across the calendar,
     weekly stats and workout confirmation.
   - `mealLoggedNotificationBody` also prefers the persisted burn.

5. **Testing & Verification**
   - `test/features/m44_task2_green_stomach_test.dart`,
     `test/ui/blueprint_grid_painter_test.dart`,
     `test/features/m44_task4_weekly_calendar_data_test.dart`.
   - `fvm flutter analyze` clean; full `fvm flutter test` green.

## Key identifiers (backend-identical payload keys)
- `body_blueprint_grid`, `body_blueprint_paint`, `unified_body_blueprint`
- `SegmentStatus.healthy`, `BodySegmentPalette.healthy` (`#10B981`)
- `DailyEntry.burned`, `DailyEntry.exercises`

## Risks / notes
- The organic torso and grid are visual changes; the blueprint golden was
  regenerated (the grid is a separate painter, not part of that golden).
- Adding `SegmentStatus.healthy` is additive and does not change the existing
  balanced/warning/critical behaviour.
