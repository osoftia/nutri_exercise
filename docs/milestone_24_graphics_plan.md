# Milestone 24 — Advanced Graphics & Exercise Color Mapping

> **Author:** @Architect
> **Status:** Ready for @Coder implementation (strict TDD per `.opencode.md`)
> **Branch:** `feature/m24-advanced-graphics-heatmap`
> **Contract:** `docs/specs/m24_graphics.feature`

## 0. Goal

When the user selects or logs an exercise (e.g. "Bench Press"), the body map
must highlight exactly the muscles that exercise activates — primary movers in
Red, secondary movers in Orange — while every non-targeted region keeps its
default muscle color. Color changes must animate smoothly, replace cleanly on
re-selection, and never crash on unknown exercises or unknown region ids.

This milestone is UI/state only. No backend change. No new API.

## 1. Current state (verified)

- `MuscleTamagotchiState` (`lib/core/state/muscle_tamagotchi_state.dart`) owns
  `massOf` / `tierOf` / `applyGrowth` / `applyDecay`, plus the M22 `coreFullness`
  / `coreIsBloating` / `applyNutrition` / `settleCore` / `settledCoreScale`.
  It has **no** notion of per-region color overrides.
- `InteractiveBodyMap` (`lib/ui/organisms/interactive_body_map.dart` — NOTE:
  the correct path is `organisms/`, not `molecules/`) renders via `CustomPaint`
  + `_BodyMapPainter`. `_regionColor()` resolves tier / neutral / bloat-red.
  `_regionScale()` handles mass + core overshoot. `_bloatController` and
  `_glowController` run under `TickerProviderStateMixin`. `shouldRepaint`
  already tracks `revision`, `bodyWidthFactor`, `coreBloating`, `bloat`.
- Region ids from `lib/core/constants/muscle_vectors.dart`: `chest`, `abs`,
  `arms`, `legs`, `shoulders`, `back` (left/right pairs share the same id).
- Group mapping from `lib/core/constants/tamagotchi_groups.dart`:
  core → `abs, back`; arms → `arms, shoulders`; chest → `chest`; legs → `legs`.
  Tier colors: C red, B yellow, A green, S gold.
- Theme colors in `lib/core/theme/app_theme.dart`: `danger` red `0xFFEF4444`
  (primary activation), `accent` orange `0xFFF97316` (secondary activation),
  `neutralMuscle` default, plus `primary*` / `success` / `warning` / `gold`.

## 2. New utility — `lib/core/utils/exercise_muscle_mapper.dart`

Create a small pure-Dart lookup (no widgets, no async) that maps a normalized
exercise name to primary and secondary **region ids** (not group enums, so the
painter can address exact vectors).

Design contract (signatures only — no implementation in this phase):

```dart
class ExerciseActivation {
  const ExerciseActivation({
    required this.primaryRegions,
    required this.secondaryRegions,
  });
  final List<String> primaryRegions;
  final List<String> secondaryRegions;
}

class ExerciseMuscleMapper {
  /// Returns activation for [exerciseName] (case/whitespace-insensitive).
  /// Unknown names return empty primary and secondary lists (never throws).
  static ExerciseActivation activationFor(String exerciseName);
}
```

Seed dictionary (minimum — Coder may extend only with existing region ids):

| Exercise | Primary regions | Secondary regions |
|---|---|---|
| Bench Press | `chest` | `arms`, `shoulders` |
| Overhead Press | `shoulders` | `arms`, `chest` |
| Biceps Curl | `arms` | _(none)_ |
| Triceps Pushdown | `arms` | `chest` |
| Back Row | `back` | `arms` |
| Squat | `legs` | `back` |
| Deadlift | `back`, `legs` | `arms` |
| Crunch | `abs` | _(none)_ |

Rules:
- Every id in the dictionary MUST exist in `muscleRegions` (valid ids:
  `chest`, `abs`, `arms`, `legs`, `shoulders`, `back`).
- Normalization: trim + lowercase; collapse internal whitespace.
- Unknown exercise → `ExerciseActivation(primaryRegions: [], secondaryRegions: [])`.
- Unknown region ids must never be produced by the mapper; defensively, the
  painter must also ignore override keys that match no region.

## 3. State change — `Map<String, Color> regionColorOverrides`

Extend `MuscleTamagotchiState` with a per-region override map keyed by region
id (e.g. `chest` → Red). This is orthogonal to mass/tier/bloat state.

Design contract (signatures only):

```dart
Map<String, Color> get regionColorOverrides; // unmodifiable view
Color? overrideColorFor(String regionId);
void setExerciseActivation(ExerciseActivation activation);
void clearExerciseActivation();
```

Semantics:
- `setExerciseActivation` clears any previous overrides, then sets primary
  regions to Red (`AppColors.danger`) and secondary regions to Orange
  (`AppColors.accent`), then `notifyListeners()`.
- `clearExerciseActivation` empties the map and `notifyListeners()` (no-op if
  already empty, but must still be safe to call).
- Overrides never affect `massOf` / `tierOf` / `coreFullness`; they are a pure
  presentation layer.
- The map must be exposed as an unmodifiable view so widgets cannot mutate
  state without notification.

## 4. Widget change — `lib/ui/organisms/interactive_body_map.dart`

Apply overrides in the existing painter with smooth animation. Two coordinated
pieces:

### 4a. Resolve the effective color per region

In `_BodyMapPainter._regionColor()`, insert override precedence at the top
(after the null-state guard), below the transient core-bloat red which keeps
highest precedence as specified in M22:

1. Tamagotchi state null → `neutralMuscle` (unchanged).
2. Core region while `coreBloating` → bloat red (unchanged, M22 behavior wins).
3. **NEW:** override present for `region.id` → the override color.
4. Otherwise → existing tier/default resolution (unchanged).

Unknown override keys (no matching `region.id`) are ignored during paint.

### 4b. Animate the transition with the existing TweenAnimationBuilder pattern

Color overrides must not snap. Recommended approach (Coder to implement):

- Keep the painter itself synchronous (it receives resolved `Color`s).
- Animate at the widget layer using the existing `TweenAnimationBuilder`
  pattern already used elsewhere in the codebase (e.g. the projection avatar's
  nested `TweenAnimationBuilder` for shoulder/waist morph): wrap the
  `InteractiveBodyMap` (or the `CustomPaint`) so that when
  `regionColorOverrides` changes, each affected region's color tweens from the
  previous resolved color to the new resolved color over ~300–500 ms.
- `shouldRepaint` must also return true when the overrides revision changes
  (e.g. compare the overrides map identity or a revision counter bumped on
  every `setExerciseActivation` / `clearExerciseActivation`), alongside the
  existing `revision` / `bodyWidthFactor` / `coreBloating` / `bloat` checks.
- The existing `_bloatController` / `_glowController` lifecycles
  (`TickerProviderStateMixin`, dispose) must remain untouched.

### 4c. Vector rendering polish (scoped)

- No changes to the normalized vector paths themselves.
- Ensure override fills respect the existing alpha behavior for
  selected vs. dimmed regions: non-targeted regions keep their current dim
  treatment when a selection/exercise highlight is active (i.e. targeted
  regions pop at full activation color; everything else stays at the default
  dimmed alpha).
- Preserve all existing `// ignore: deprecated_member_use` tags on legacy
  `translate` / `scale` cascades; any touched cascade keeps the ignore comment
  on the line above so both the local and CI SDKs pass.

## 5. UI connection (no new screen)

Selection/logging of an exercise calls, in order:

1. `ExerciseMuscleMapper.activationFor(name)` →
2. `tamagotchiState.setExerciseActivation(activation)` (or
   `clearExerciseActivation()` on deselect) →
3. `InteractiveBodyMap` rebuilds (via existing `notifyListeners` → `_revision`)
   and animates to the new colors.

The plan does not introduce a new route or page; the existing exercise
selection/logging entry points feed the same shared `MuscleTamagotchiState`
instance already provided to the avatar.

## 6. Files

**New (Coder Phase 2/3)**
- `lib/core/utils/exercise_muscle_mapper.dart` — dictionary + `activationFor`.
- Tests: `test/core/utils/exercise_muscle_mapper_test.dart` (Red phase),
  plus state/widget tests for overrides and transitions.

**Modified (Coder Phase 2/3)**
- `lib/core/state/muscle_tamagotchi_state.dart` — override map + set/clear API.
- `lib/ui/organisms/interactive_body_map.dart` — override resolution +
  animated application + `shouldRepaint` extension (correct path is
  `organisms/`, not `molecules/`).

## 7. Testability (BDD → TDD mapping)

| Gherkin scenario | Target test(s) |
|---|---|
| Bench Press maps to Chest/Triceps groups | `activationFor('Bench Press')` returns primary `chest`, secondary contains `arms`/`shoulders`; all ids exist in `muscleRegions` |
| Overrides carry Red/Orange, rest default | `setExerciseActivation` sets `chest`→Red, `arms`/`shoulders`→Orange; untouched regions have no override |
| Clearing removes overrides | `clearExerciseActivation` empties the map |
| Smooth TweenAnimationBuilder transition | Widget test pumps old→new overrides and asserts intermediate frames differ from both endpoints |
| Replacement without residue | Second `setExerciseActivation` drops prior keys |
| Unknown exercise / unknown region | Empty activation; painter ignores unknown keys without throwing |

Follow the repo's existing fake patterns (in-memory state, `Key`-addressable
painters/values) for deterministic widget assertions.

## 8. Out of scope

- Backend persistence of overrides or exercise logs (backend milestone paused).
- Changing normalized vector geometry.
- New screens, routes, or navigation.
- Persisting overrides across restarts.
- Any change to mass/tier/bloat semantics from M19/M22.
