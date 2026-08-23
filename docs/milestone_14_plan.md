# Milestone 14 — Nutrition Dashboard, Neumorphic Stats & Dynamic Avatar Plan

> **Author:** @Architect
> **Status:** Ready for @Coder implementation (strict TDD)
> **Branch:** `feature/m14-nutrition-dynamic-avatar`
> **Contract:** `mobile_app/test/features/m14_nutrition.feature`

---

## 1. Scope

Give life to the **NUTRITION** tab (index 1 of the `MainShellPage`) by turning
the static mock plan into an interactive nutrition dashboard:

1. **Neumorphic charts** — circular progress indicators for the three
   macronutrients (Protein, Carbs, Fat) and a bar chart of weekly calories.
2. **Food intake mock form** — quick-add meal buttons + a small log form that
   adds calories (and macro grams) to the day's totals.
3. **Dynamic human avatar** — a `CustomPaint` human silhouette whose shape
   morphs (thinner ↔ wider) with the ratio of consumed vs target calories.
4. **State management** — a `ChangeNotifier` controller (M12/M13 pattern) so
   logged food is reflected immediately in the charts and avatar.

All data is mock/seeded in-memory; no persistence or networking is required.

---

## 2. Current state analysis

- `lib/ui/pages/nutrition_page.dart` is a **StatelessWidget** showing a static
  "Daily Plan" row (`_mockPlan` meals: Oatmeal & Berries 420, Grilled Chicken
  Bowl 650, Salmon & Quinoa 580, Greek Yogurt & Almonds 240) summed into a
  `totalCalories`. No charts, no logging, no avatar, no state.
- Reusable atoms available from M11/M12:
  - `NeumorphicContainer` (now provides a transparent `Material` ancestor).
  - `AppColors`, `AppSpacing`, `AppRadius`, `AppHeading`/`AppText`/`AppCaption`,
    `NeumorphicStyles` shadow tokens.
- Controller pattern established in M12 (`UserProfileController`) and M13
  (`ScheduleController`): `ChangeNotifier` + constructor-DI + `ListenableBuilder`.

### Gaps to fill (Green phase)
- `FoodEntry` model + macro targets.
- `NutritionRepository` (abstract) + `MockNutritionRepository` seeded baseline.
- `NutritionController extends ChangeNotifier` (calories, macros, entries,
  weekly stats, logging methods, derived getters).
- Three custom-paint atoms: circular macro ring, weekly bar chart, dynamic
  avatar silhouette.
- Rewrite `NutritionPage` + wire through `MainShellPage`/`app.dart`.

---

## 3. New components

### 3.1 Model — `lib/core/models/food_entry.dart`

```dart
class FoodEntry {
  const FoodEntry({
    required this.name,
    required this.calories,
    this.proteinG = 0,
    this.carbsG = 0,
    this.fatG = 0,
  });
}
```

Macro **targets** live as constants (e.g. `MacroTargets(protein: 150, carbs:
250, fat: 70)`) — grams/day. A day's **baseline** consumed state is seeded by
the mock repository (consumed 1000 kcal, protein 30 g, carbs 80 g, fat 20 g)
so dashboard/morph assertions are deterministic.

### 3.2 Repository — `lib/core/data/nutrition_repository.dart`

```dart
abstract interface class NutritionRepository {
  Future<NutritionState> loadToday();          // seeded baseline
  Future<void> saveToday(NutritionState state); // no-op/mock persist
}
```

`NutritionState` (in `lib/core/models/nutrition_state.dart`) bundles:
`targetCalories`, `consumedCalories`, `proteinG`, `carbsG`, `fatG`,
`List<FoodEntry> entries`, `List<int> weeklyCalories` (7 values Mon–Sun).

`MockNutritionRepository` returns a fixed baseline for `loadToday()`.

### 3.3 State management — `lib/core/state/nutrition_controller.dart`

```dart
class NutritionController extends ChangeNotifier {
  NutritionController({required NutritionRepository repository});

  int targetCalories;           // 2000
  int consumedCalories;         // starts at seed
  int proteinG, carbsG, fatG;   // consumed macro grams
  List<FoodEntry> entries;
  List<int> weeklyCalories;     // 7 bars

  Future<void> load();                       // seed from repository
  void logFood(FoodEntry entry);             // add calories + macros, insert entry
  void resetDay();                           // (optional) clear the day

  // Derived (drives charts + avatar):
  double get calorieRatio;                   // consumed / target
  double get morphFactor;                    // [0,1] -> avatar shape
  double get proteinProgress;                // proteinG / proteinTarget
  double get carbsProgress;
  double get fatProgress;
}
```

Every mutator calls `notifyListeners()` so the page (via `ListenableBuilder`)
re-renders charts and avatar on the same frame.

### 3.4 UI atoms (all `CustomPaint`-based, neumorphic styled)

1. **`lib/ui/atoms/neumorphic_circular_progress.dart`** — a ring for one
   metric:
   - Track: full-circle stroke (`AppColors.surface900`, width ~10).
   - Progress: `drawArc` stroke (`AppColors.primary400` or accent), sweep
     `2π * progress`.
   - Center label (value + target), title caption.
   - Wrapped in `NeumorphicContainer` by the page.
2. **`lib/ui/atoms/neumorphic_bar_chart.dart`** — weekly calories:
   - 7 bars, normalized height `barValue / maxWeeklyValue`.
   - Each bar a rounded `RRect` (`AppColors.primary500.withOpacity(0.6)`),
     drawn on a subtle track; weekday captions beneath.
   - Exposes a `Semantics`/label or `Key` for tests (`weekly_bar_<i>`).
3. **`lib/ui/atoms/dynamic_avatar.dart`** — the morphing silhouette (see §4).

### 3.5 UI — rewrite `lib/ui/pages/nutrition_page.dart`

`NutritionPage({required NutritionController controller})`, `ListenableBuilder`:

- **Header**: `AppHeading('Nutrition')` + consumed/target summary card
  (`Key('calorie_summary')`) showing `"1000 of 2000 kcal"`.
- **Dynamic avatar** (`Key('dynamic_avatar')`) — morph driven by controller.
- **Macro section**: three `NeumorphicCircularProgress` (Protein/Carbs/Fat).
- **Weekly chart**: `NeumorphicBarChart` (`Key('weekly_bar_chart')`).
- **Food intake form**: quick-add buttons for the seeded meals
  (`Key('quick_add_<name>')`) each calling `controller.logFood(...)`, plus a
  small `TextField` + "Add" (`Key('food_name_field')` / `Key('food_add_button')`)
  for a custom entry (name + calories) with numeric validation.

### 3.6 Wiring

- `lib/ui/pages/main_shell_page.dart`: accept a required `NutritionController`
  and pass it to `NutritionPage`.
- `lib/app.dart`: build `MockNutritionRepository` + `NutritionController`,
  inject into `MainShellPage`.

---

## 4. Dynamic Avatar — CustomPainter morphing math (detailed)

### 4.1 Calorie ratio → morph factor

Let `ratio = consumedCalories / targetCalories`.

Map to a normalized morph factor `t ∈ [0, 1]` with **0 = thinnest,
0.5 = normal build, 1 = widest**:

```
t = clamp((ratio − 0.5) / 1.0, 0.0, 1.0)
```

- `ratio ≤ 0.5` → `t = 0` (very lean / under-eating).
- `ratio = 1.0` (met target) → `t = 0.5` (normal).
- `ratio = 1.5` → `t = 1.0` (heavy / over-eating).
- `ratio > 1.5` → clamped at `1.0`; `ratio < 0.5` → clamped at `0.0`.

`t` is exposed by `NutritionController.morphFactor` so tests can assert it
directly and the painter consumes it as a plain parameter.

### 4.2 Silhouette as two vertex sets

Define the body in a **normalized 0..1 box** (x right, y down). Two anchor
silhouettes, **same number of vertices, same ordering** (clockwise from head):

```
thin = [ head top, head right, shoulder, upper arm, elbow, lower arm,
         hand, waist, hip, thigh, knee, shin, foot, (mirrored back up) ]
wide = [ same points with larger x-radii, belly bulge, thicker limbs ]
```

Concretely (x offsets relative to a vertical centerline `cx = 0.5`):

| Point      | thin `dx` | wide `dx` | effect as t grows |
|-----------|-----------|-----------|-------------------|
| head radius | 0.045 | 0.060 | slightly larger head |
| shoulder   | 0.170 | 0.210 | broader shoulders |
| arm outer  | 0.260 | 0.310 | thicker arms |
| waist      | 0.110 | 0.210 | belly widens fastest |
| belly bulge (torso mid) | 0.095 | 0.235 | protruding belly |
| hip        | 0.150 | 0.200 | wider hips |
| thigh      | 0.120 | 0.175 | thicker thighs |
| calf       | 0.085 | 0.125 | thicker calves |

The **belly bulge** uses an extra waist control whose `dx` grows
disproportionately with `t` (quadratic emphasis):

```
bellyDx(t) = lerp(thin.belly, wide.belly, t)        // linear
waistDx(t) = lerp(thin.waist, wide.waist, t) + 0.06 * pow(t − 0.5, 2) // belly pooch near/above normal
```

### 4.3 Vertex interpolation

Because both anchors share vertex indices, per-vertex linear interpolation
gives a smooth morph with **zero topology changes**:

```
vertex_i(t) = Offset(
  cx + (thin_i.dx + (wide_i.dx − thin_i.dx) * t),
  thin_i.dy,              // y stays constant (height is fixed)
)
```

### 4.4 Path building & painting

1. `paint(Canvas, Size)`:
   - compute `unit = size.shortestSide` and translate normalized coords:
     `p = vertex_i(t) * unit` (plus centering).
   - `Path ..moveTo(p0) ..cubicTo(...)` through each vertex (smooth
     silhouette) `..close()`.
   - fill with `AppColors.primary500.withOpacity(0.35)`; stroke
     `AppColors.primary400` (width 2).
2. Expose the painter (`DynamicAvatarPainter`) with public `morph` and a
   `shouldRepaint(old) => old.morph != morph`.
3. `DynamicAvatar` widget: `CustomPaint(key: Key('dynamic_avatar'),
   painter: DynamicAvatarPainter(morph: morph))` inside a `NeumorphicContainer`.

### 4.5 Testability

- `NutritionController.morphFactor` is the single source of truth; the avatar
  painter just renders `morph`. Unit tests assert `morphFactor` at seeded
  ratios (1000/2000 → `t < 0.5`; 2200/2000 → `t > 0.5`).
- Widget tests locate `DynamicAvatarPainter` via the `CustomPaint` under
  `Key('dynamic_avatar')` and assert its `morph` changed after `logFood`.
- A pure helper `double morphFactorFor(int consumed, int target)` (top-level,
  in the painter file) is unit-tested directly for boundary values
  (0.5 → 0.0, 1.0 → 0.5, 1.5 → 1.0, clamps).

---

## 5. Chart math (reference)

**Circular ring** (per macro):
```
sweepAngle = 2π * progress       // progress = consumedG / targetG (clamped 0..1)
startAngle = −π/2 (12 o'clock)
Paint.style = stroke, strokeWidth = 10, strokeCap = round
```

**Weekly bar chart**:
```
maxWeekly = weeklyCalories.max (guard divide-by-zero -> 1)
barHeight_i = (weeklyCalories[i] / maxWeekly) * chartHeight
barRect_i   = RRect(rounded top, width = chartWidth/7 − gap)
```

---

## 6. Mocking strategy for tests

- **`MockNutritionRepository`** seeds a deterministic `NutritionState`:
  target 2000 kcal, consumed 1000 kcal, protein 30 g / carbs 80 g / fat 20 g,
  no logged entries, `weeklyCalories` = fixed 7 values (e.g.
  `[1800, 1500, 1200, 2000, 1750, 2400, 1450]`).
- Quick-add buttons map to seeded `FoodEntry`s (Grilled Chicken Bowl +650 kcal,
  Protein Shake +30 g protein, Oatmeal & Berries +420 kcal, etc.).
- Controller unit tests drive `logFood` and assert getters/`notifyListeners`.
- **Existing M11 shell test** (`m11_navigation_widget_test.dart`) is updated
  like M12/M13: pump `MainShellPage` with a mock-backed `NutritionController`;
  the Nutrition-tab scenario asserts the new dashboard (calorie summary +
  charts) instead of the static meal list. `widget_test.dart`'s `NutriApp`
  test continues to pass via `useMocks`.

---

## 7. TDD Execution Order (for @Coder)

Follow Red → Green strictly. Run `flutter test` (target file) after each step;
`flutter analyze` at the end of Green.

| Step | Test (RED) | Implementation (GREEN) |
|------|-----------|------------------------|
| 0 | (contract) keep `test/features/m14_nutrition.feature` as source of truth | — |
| 1 | **Model + morph math test** `test/models/food_entry_test.dart` + `test/ui/dynamic_avatar_test.dart` (pure helper `morphFactorFor`): boundaries 0.5→0, 1.0→0.5, 1.5→1, clamps; `FoodEntry` construction. (RED: classes missing) | Create `FoodEntry`, `NutritionState`, `MacroTargets`, and `morphFactorFor(...)` helper. |
| 2 | **Repo test** `test/data/nutrition_repository_test.dart`: `MockNutritionRepository.loadToday()` returns the seeded baseline (1000/2000, macros). (RED) | Create `NutritionRepository` + `MockNutritionRepository`. |
| 3 | **Controller test** `test/state/nutrition_controller_test.dart`: load seeds state; `logFood` adds calories + macros + entry + notifies; `morphFactor`/macro-progress getters correct at seeded values and after logging. (RED) | Create `NutritionController`. |
| 4 | **Chart widget tests** `test/ui/neumorphic_circular_progress_test.dart`, `test/ui/neumorphic_bar_chart_test.dart`: ring paints sweep per progress; bar chart renders 7 bars + normalized heights. (RED) | Create both `CustomPaint` atoms. |
| 5 | **Nutrition page widget test** `test/features/m14_nutrition_widget_test.dart`: summary shows consumed/target; three macro rings; weekly chart; quick-add increments calories + macro ring + avatar morph; avatar morph thin/wide at seeded ratios; logged food reflected across charts + avatar. (RED: page static) | Rewrite `NutritionPage` + wire atoms + controller. |
| 6 | **Shell wiring**: update `main_shell_page.dart` + `app.dart`; update `m11_navigation_widget_test.dart` Nutrition scenario; verify `widget_test.dart`. (RED until wired) | Wire `NutritionController` through `MainShellPage`/`NutriApp`. |
| 7 | **Regression + log + commit**: full `flutter test`, `flutter analyze`, `docs/m14_execution_changes.log`, `git add .` + commit. | — |

---

## 8. Files created / modified (proposal)

```
mobile_app/
├── test/
│   ├── features/
│   │   ├── m14_nutrition.feature               # BDD contract (this milestone)
│   │   ├── m14_nutrition_widget_test.dart      # step 5
│   │   └── m11_navigation_widget_test.dart     # step 6 (modified)
│   ├── models/
│   │   └── food_entry_test.dart                # step 1
│   ├── data/
│   │   └── nutrition_repository_test.dart      # step 2
│   ├── state/
│   │   └── nutrition_controller_test.dart      # step 3
│   └── ui/
│       ├── dynamic_avatar_test.dart            # step 1 (morph helper)
│       ├── neumorphic_circular_progress_test.dart  # step 4
│       └── neumorphic_bar_chart_test.dart      # step 4
├── lib/core/
│   ├── models/
│   │   ├── food_entry.dart                     # FoodEntry + MacroTargets
│   │   └── nutrition_state.dart                # NutritionState
│   ├── data/
│   │   └── nutrition_repository.dart           # abstract
│   ├── mocks/
│   │   └── mock_nutrition_repository.dart
│   └── state/
│       └── nutrition_controller.dart           # ChangeNotifier
├── lib/ui/
│   ├── atoms/
│   │   ├── neumorphic_circular_progress.dart   # ring (new)
│   │   ├── neumorphic_bar_chart.dart           # weekly bars (new)
│   │   └── dynamic_avatar.dart                 # morphing silhouette + morphFactorFor (new)
│   └── pages/
│       ├── nutrition_page.dart                 # rewritten (modified)
│       └── main_shell_page.dart                # DI controller (modified)
├── lib/app.dart                                # wire controller (modified)
└── docs/
    └── m14_execution_changes.log               # Coder log
```

---

## 9. Definition of Done (DoD)

- Every scenario in `test/features/m14_nutrition.feature` has a passing test.
- `flutter test` green (full suite, no regressions).
- `flutter analyze` reports no issues introduced by this milestone.
- Logging food updates consumed calories, macro rings, weekly bar chart and
  avatar morph factor immediately (ChangeNotifier).
- Avatar morph factor math: 0.5→0, 1.0→0.5, 1.5→1 with clamps (unit-tested).
- Three macro circular progress indicators + 7-bar weekly chart rendered with
  the neumorphic aesthetic.
- Food-intake quick-add buttons and custom-entry form validate input.
- `docs/m14_execution_changes.log` written and committed.

---

## 10. Open decisions (non-blocking)

1. **Target calories source** — hardcoded 2000 kcal default vs. deriving from
   `UserProfileController` (age/weight/goal). Recommend hardcoded default for
   M14; BMI/TDEE integration is a follow-up.
2. **Macro targets** — fixed grams/day (150/250/70). Custom targets are a
   follow-up.
3. **Persistence** — mock/in-memory only for M14; a `LocalNutritionRepository`
   on SQLite (daily rows) is a follow-up.
4. **Avatar realism** — the silhouette is stylized (no face, limbs merged with
   torso); facial features and clothing can be added later. The interpolated
   two-anchor approach keeps the morph cheap and testable.
5. **Logging UI** — quick-add buttons for seeded meals + one custom
   name/calories entry; multi-line meal logging is a follow-up.