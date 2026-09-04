# Milestone 22 — Dynamic BMI Avatar & Nutrition Visualizer

> **Author:** @Architect
> **Status:** Ready for @Coder implementation (strict TDD per `.opencode.md`)
> **Branch:** `feature/m22-dynamic-avatar-nutrition`
> **Contract:** `docs/specs/m22_dynamic_avatar.feature`

## 0. Scope & context

M21 connected the Daily Log UI to the backend `POST /api/log/parse`, storing the
parsed `LogParseResponse` (calories, protein, carbs, fat, muscle groups) in
`DailyLogController.parseResult`. M19 built the Tamagotchi avatar
(`MuscleTamagotchiState` + `InteractiveBodyMap`) that scales/colours four muscle
groups by workout *mass*.

This milestone bridges the two: the AI-parsed nutrition data now feeds the
avatar, and the baseline avatar proportions are made profile-aware via BMI.

Three workstreams:

1. **Nutrition totals UI** — surface the daily Calories / Protein / Fat totals.
2. **Profile-aware baseline proportions** — derive a body-width factor from the
   user's BMI and apply it to the avatar's base matrices.
3. **Core "eat → bloat" reaction** — on new calories, the Core region flashes
   red, temporarily balloons, then settles at a slightly larger permanent size.

Mobile-only. No backend change.

---

## 1. Workstream A — Nutrition totals UI

The parsed values already live in `DailyLogController` (`parseResult` →
`LogParseResponse`). Two gaps:

1. The controller only holds the **last submitted** log, not an accumulated
   **daily total** (multiple logs per day).
2. There is no UI showing calories/protein/fat anywhere.

### 1.1 Daily totals state

Introduce a `DailyNutritionState` (a `ChangeNotifier`) that accumulates totals:

```dart
class DailyNutritionState extends ChangeNotifier {
  double calories;
  double protein;
  double fat;
  void add(LogParseResponse result);   // accumulates onto today
  void resetTo(LogParseResponse r);    // replaces today's totals
  void reset();                        // new day / test reset
}
```

Aggregation: per-day totals keyed by date (mirroring `DailyLog.dateKey`). On a
new day the totals reset to zero. Design decision left to the Coder's reuse of
the existing `nutrition_controller.dart` pattern (the app already has a
`NutritionController` that tracks `consumedCalories`/macros — the Coder should
**extend that controller** if it can host the parsed totals, or add a parallel
`DailyNutritionState` if that is cleaner; the contract only requires the totals
to be observable and accumulated).

### 1.2 Daily totals UI

Two surfaces, either is acceptable (recommend the snackbar + a dedicated card):

1. **Post-save SnackBar** (already exists in `DailyLogSheet`) — extend to show
   protein and fat, not just calories/kcal.
2. **A `DailyTotalsCard`** rendered on the Home dashboard (near the Muscle Map)
   showing `Daily Totals · 650 kcal · 45 g Protein · 18 g Fat`, with keys
   `daily_calories_total`, `daily_protein_total`, `daily_fat_total` so the
   Gherkin scenarios can assert the values deterministically.

---

## 2. Workstream B — Profile-aware baseline proportions (BMI)

The avatar today renders each region at a neutral scale regardless of the user's
body. We derive a **body width factor** from BMI and feed it into the same
scaling matrices.

### 2.1 BMI → width factor

```dart
double bmi(double heightCm, double weightKg) => weightKg / pow(heightCm / 100, 2);

// Maps BMI to a width factor. BMI ~22 (normal) → 1.0, slimmer < 1.0,
// heavier > 1.0, clamped to a sane range.
double widthFactorForBmi(double bmi);
```

- `height 170 cm, weight 70 kg` → BMI ≈ `24.2` (upper-normal) → width factor
  ≈ normal/slimmer (`≈ 1.0` or slightly below).
- `height 170 cm, weight 95 kg` → BMI ≈ `32.9` (obese) → clearly **larger**
  width factor than the 70 kg case (satisfying the "wider baseline" scenario).
- Propose a linear mapping `widthFactor = 1 + k * (bmi - 22)` with `k ≈ 0.03`,
  clamped to `[0.75, 1.45]`. Exact constants are the Coder's to tune; the
  contract requires monotonicity (higher BMI → wider) and a normal/slim result
  for 170/70.

### 2.2 Where the factor is applied

`InteractiveBodyMap` computes screen paths in `_screenPath` via `_figureBox` and
a scale matrix. Add a per-instance `bodyWidthFactor` (default `1.0`) that:

- scales the **front/back silhouette** and all region paths **horizontally**
  around the figure centre (a non-uniform `Matrix4` scale, or a uniform scale
  applied to the width dimension only), so a heavier BMI widens the body without
  changing its height.

The factor must be composable with the existing per-group `scaleForMass` (mass)
so workout growth still works on top of the BMI baseline. Recommendation:
compute `effectiveScale = widthFactor * scaleForMass(mass)` in the painter's
`_regionPath`, keeping the vertical component at `scaleForMass(mass)`.

### 2.3 Profile source

The avatar needs the user's `heightCm`/`weightKg`. Today `MuscleGroupVisualizer`
is built inside `HomePage` (a `StatefulWidget` that already owns a
`MuscleTamagotchiState`) but has no access to the profile. Options:

- Lift a `UserProfileController` (or the loaded `UserProfile`) into `HomePage`
  and thread `heightCm`/`weightKg` into `MuscleGroupVisualizer` →
  `InteractiveBodyMap.bodyWidthFactor`.
- Deeper option: place `InteractiveBodyMap`'s `bodyWidthFactor` computation in a
  small pure helper (`bmi`, `widthFactorForBmi`) tested in isolation, and feed
  the result in at the UI layer.

The pure helpers live in the core (`core/state/` or `core/constants/`) so they
are unit-testable without widgets.

---

## 3. Workstream C — Core "eat → bloat" reaction

Requirement: on consuming calories, the **Core** region
1. temporarily turns **red**,
2. **expands** beyond its eventual settle size,
3. **settles** at a slightly larger **permanent** scale proportional to calories.

This is a two-phase animation + a persistent scale bump, all driven by state so
the existing `CustomPaint` repaints.

### 3.1 State — `MuscleTamagotchiState` extension

Add a nutrition-specific, transient + persistent concept that does **not** touch
workout `mass`:

```dart
/// Calories-driven core fullness, 0..1 (baseline 0). Higher = fuller core.
double coreFullness;

/// Fired when new calories are logged; advances an animation phase and
/// raises coreFullness in proportion to calories.
void applyNutrition(int calories);          // adds calories → fullness += f(calories)
double get coreReactionProgress;            // 0..1 animation phase (transient)
bool get coreIsBloating;                    // true while the bloat is animating
```

- `applyNutrition` sets `coreReactionProgress` to `0` (start of the red/bloat
  phase), bumps `coreFullness` by a token proportional to calories
  (e.g. `fullnessDelta = clamp(calories / 2000, 0.05, 1.0)` per log, clamped to
  `1.0`), then the animation controller (owned by the widget, see 3.2) advances
  `coreReactionProgress` from `0 → 1`, after which it settles.
- Cumulative calories map monotonically to `coreFullness`, satisfying the
  "400 kcal vs 1000 kcal" scenario.

### 3.2 Widget — `InteractiveBodyMap` animation

The widget already listens to `tamagotchiState` (`_onTamagotchiChanged` →
`_revision++`) and owns an `AnimationController` (`_glowController`). Add a
second `AnimationController` (`_bloatController`, ~800 ms, single-shot) that:

- On `applyNutrition`, `_bloatController.forward(from: 0)`.
- During the animation, `setState` drives a **bloat scale** for the Core region
  that *overshoots* (e.g. `1 + 0.25 * (1 - progress)` extra) and tints it **red**
  (blend toward `AppColors.danger`).
- When the animation completes, the Core renders at its settled scale derived
  from `coreFullness` (permanent, slightly larger).

The Core colour/scale logic all happens in `_BodyMapPainter.paint` by mixing
`coreFullness` (settled scale) and `coreReactionProgress` (transient overshoot +
red tint) for regions whose group is `MuscleTamagotchiGroup.core` (region ids
`abs`, `back` from `tamagotchiGroupToRegions`).

### 3.3 Composing with existing mass/tier colouring

Precedence for the Core region resolves as:

1. If `coreReactionProgress < 1` → red tint + overshoot scale (transient).
2. Else → tier colour (existing `tierColor`) but scale multiplied by
   `(1 + bloatSettleScaleFrom(coreFullness))`.

This keeps the M19 heatmap behaviour while layering the nutrition reaction.

---

## 4. Files

**New**
- `lib/core/state/daily_nutrition_state.dart` — daily totals accumulation (or
  reuse/extend `NutritionController`).
- `lib/core/state/body_proportions.dart` — pure `bmi(...)` and
  `widthFactorForBmi(...)` helpers (or fold into the tamagotchi state file).
- `lib/ui/molecules/daily_totals_card.dart` — the totals card (keys above).

**Modified**
- `lib/core/state/muscle_tamagotchi_state.dart` — add `coreFullness`,
  `applyNutrition`, `coreReactionProgress`, `coreIsBloating`.
- `lib/ui/organisms/interactive_body_map.dart` — add `bodyWidthFactor`,
  `_bloatController`, core bloat/red-tint painting, BMI-composite scaling.
- `lib/ui/organisms/muscle_group_visualizer.dart` — thread `bodyWidthFactor`.
- `lib/ui/pages/home_page.dart` — read profile → `bodyWidthFactor`, feed the
  totals card + wire `applyNutrition` from `DailyLogController` parse results.
- `lib/ui/molecules/daily_log_sheet.dart` — extend the success SnackBar with
  protein/fat and/or call the nutrition state.
- `lib/app.dart` — optionally construct/provide the new state and connect
  `DailyLogController` → `applyNutrition`.

**Spec**
- `docs/specs/m22_dynamic_avatar.feature` (created).

---

## 5. Testability (BDD → TDD mapping)

| Gherkin scenario | Target test(s) |
|---|---|
| Daily totals shown (kcal/protein/fat) | `daily_nutrition_state_test.dart` (accumulation) + `daily_totals_card` widget test asserting `daily_calories_total` etc. |
| BMI scaling — 170/70 normal/slim | pure `widthFactorForBmi` unit test: factor ≈ normal for BMI ~24, monotonic. |
| Heavier profile wider | `widthFactorForBmi(32.9) > widthFactorForBmi(24.2)`. |
| Core bloats red then settles larger | `muscle_tamagotchi_state_test.dart` (`applyNutrition` raises `coreFullness`); `interactive_body_map` widget test drives the bloat controller and asserts the Core region's transient scale/colour and settled scale. |
| Accumulation (400 → 1000 kcal) | `applyNutrition` twice → `coreFullness(1000) > coreFullness(400)`. |

Follow the existing fake patterns: SQLite FFI for repositories, fake platform
for notifications, `MockClient` for HTTP, and `Key`-addressable painters/values
for deterministic widget assertions (already used in `interactive_body_map`'s
region keys and `projection_avatar`).

---

## 6. Out of scope

- Backend storage of nutrition totals (still local; backend milestone paused).
- Full body-fat / lean-mass modelling — BMI drives width only.
- Persistent per-day energy graphs (existing `NeumorphicBarChart` may be reused
  later, not required now).
- Cross-day nutrition history UI — only *today's* totals are required.
- Changing `NutritionController`'s existing quick-add meal flows beyond hosting
  (or being replaced by) the parsed totals.
