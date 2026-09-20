# Milestone 44 (Exact) Plan — Exact Avatar Silhouette & Data Views

## Git branch
`feature/m44-exact-avatar` (delivered as per-task commits on `main`).

## Goal
Refine the shared body blueprint to the exact intended organic silhouette
(slimmer limbs, smooth torso, clean articulated joints), and reaffirm the green
protein-stomach semantics, technical grid and history-data fixes from the
earlier M44 pass under one verifiable contract.

## Gherkin contract
`mobile_app/test/features/m44_exact_avatar.feature`

## Task breakdown
1. **Exact Avatar Silhouette Restoration**
   - `BodySegmentGeometry`: slimmer limb half-widths (arms `0.052→0.042`,
     forearms `0.045→0.034`, thighs `0.075→0.062`, calves `0.058→0.046`), a
     cleaner `jointGap` (`0.016→0.022`) and cubic-Bézier torso sides that flare
     to the wider baseline half-width (rounded shoulder / belly) and taper back,
     so the chest/abdomen are smooth anatomical volumes.
   - `BodyBlueprintPainter`: outline stroke `1.6→1.4` for a crisp technical line.
   - Golden regenerated; limb width + joint gap contract tests added.

2. **Protein & Health Green Stomach Semantics** — confirmed delivered:
   `SegmentStatus.healthy` + `BodySegmentPalette` `#10B981` +
   `SegmentBalanceCalculator.isHealthySurplus`.

3. **Blueprint Technical Grid Background** — confirmed delivered:
   `BlueprintGridPainter` behind `UnifiedBodyBlueprint` in both tabs.

4. **Fix Weekly States & Calendar Data Views** — confirmed delivered:
   persisted `DailyEntry.burned` drives `computeWeeklyStats`; workout
   confirmations upsert/clear today's `DailyEntry` through one shared
   `DailyEntryRepository`.

5. **Testing & Verification**
   - New `test/ui/avatar_silhouette_test.dart` and
     `test/features/m44_task5_exact_verification_test.dart`; existing M44
     semantics/grid/data tests re-run.
   - `fvm flutter analyze` clean; full `fvm flutter test` green.

## Key identifiers
- `jointGap`, `body_blueprint_grid`, `body_blueprint_paint`
- `SegmentStatus.healthy`, `BodySegmentPalette.healthy` (`#10B981`)
- `DailyEntry.burned`, `DailyEntry.exercises`
