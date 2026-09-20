# Milestone 43 Plan — Quick Add Gram Popup, Nutrition Semantics, Unified Avatar & Standardized FABs

## Git branch
`feature/m43-avatar-nutrition-unification` (delivered as per-task commits on `main`,
mirroring the M41/M42 autonomous sprint convention).

## Goal
Unify the Routines and Nutrition tabs around a single articulated body blueprint,
make quick-add food portion-aware, and guarantee that logging food is reflected
immediately in the blueprint's abdomen colour and the Daily Nutrition Summary.

## Gherkin contract
`mobile_app/test/features/m43_avatar_nutrition.feature`

## Task breakdown
1. **Quick Add Gram Scaling Dialog**
   - New `core/domain/nutrition/portion_scaler.dart` (pure scaling of a preset's
     calories/macros by `grams / 100`).
   - New `ui/molecules/quick_add_grams_dialog.dart` (centered dialog, default 100 g,
     numeric validation).
   - `nutrition_page.dart` intercepts the quick-adds, scales the entry and mirrors
     it onto the shared body-detail log so the Tamagotchi stomach mass reacts.

2. **Nutrition Color Semantics & Summary Fix**
   - `BodyDetailController` exposes `foodLogLoaded` and marks the in-memory log as
     authority after any mutation, so the summary never clobbers a just-added item
     with a stale repository read.
   - `BodyFoodDetailSheet` only hydrates when not yet loaded and its sticky totals
     now aggregate calories, item count and summed macros.

3. **Unified Body Blueprint Component**
   - `BodySegmentGeometry` re-introduces a visible elbow/knee `jointGap` so the
     limbs are articulated (reverses the M41 "close gaps" decision by request).
   - New `ui/organisms/body_blueprint/unified_body_blueprint.dart` wraps the
     blueprint diagram with an optional callout overlay.
   - New `nutrition_body_view_model.dart` derives a calorie-responsive snapshot
     for the Nutrition tab when no body-detail controller is present; otherwise the
     live body-detail view model is used.
   - Both tabs render `UnifiedBodyBlueprint`; the old `DynamicAvatar` atom is
     removed.

4. **Standardized Floating Action Buttons**
   - New `ui/molecules/blueprint_action_rail.dart` (History FAB + summary FAB).
   - New `ui/molecules/routine_summary_sheet.dart` (Daily Routine Summary).
   - Routines: `body_history_fab` + `routine_summary_button`.
   - Nutrition: `nutrition_history_fab` + `nutrition_action_button`
     (opens the existing Daily Nutrition Summary / food sheet).

5. **Testing & Verification**
   - Feature tests under `test/features/m43_task*_test.dart` and
     `test/ui/unified_body_blueprint_test.dart`; updated geometry/avatar/golden
     expectations. `fvm flutter analyze` clean; full `fvm flutter test` green.

## Key identifiers (backend-identical payload keys)
- `quick_add_grams_dialog`, `quick_add_grams_field`, `quick_add_confirm`,
  `quick_add_cancel`
- `nutrition_total_row`, `nutrition_total_items`, `nutrition_total_macros`
- `unified_body_blueprint`, `body_blueprint_canvas`, `body_blueprint_paint`
- `body_history_fab`, `routine_summary_button`, `routine_summary_sheet`
- `nutrition_history_fab`, `nutrition_action_button`, `body_food_sheet`

## Risks / notes
- The joint-gap change is an intentional visual reversal of M41 Task 1; the golden
  `test/ui/goldens/body_blueprint_painter.png` was regenerated.
- Existing tests that encoded the pre-dialog quick-add behavior (`m14`) and the
  connected-joint geometry (`body_segment_geometry_test`) were updated to the new
  contract.
