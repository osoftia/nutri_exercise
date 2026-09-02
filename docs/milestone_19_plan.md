# Milestone 19 — Tamagotchi Interactive Avatar

> **Author:** @Architect
> **Status:** Ready for @Coder implementation (strict TDD)
> **Branch:** `feature/m19-tamagotchi-avatar`
> **Contract:** `mobile_app/test/features/m19_tamagotchi_avatar.feature`

## 1. Scope

Today the avatar is a static, selectable body map: `InteractiveBodyMap` paints
the silhouette and its `muscleRegions` with a neutral fill, and only reacts to
tap selection with a glow. Muscles never change size or colour.

This milestone turns the avatar into a **gamified "Tamagotchi"** where each
muscle group physically **grows / shrinks** and **changes colour** in response
to workout consistency:

1. A new **`MuscleTamagotchiState`** model holding a normalised `0.0..1.0`
   mass value for four groups — **Core, Arms, Chest, Legs** — plus
   **Growth** (completing routines) and **Decay** (mass lost while inactive)
   logic.
2. A refactor of **`InteractiveBodyMap`** so each group is rendered at a size
   proportional to its mass (scalable layer via `Transform.scale`, or dynamic
   `CustomPaint` region paths — see §4).
3. A **heatmap colour mapping** that recolours each group by its derived
   **tier** (C → Red … S → Gold).

This is a mobile-only milestone (no backend change). The avatar continues to be
rendered inside `MuscleGroupVisualizer` on the Routines tab.

---

## 2. Domain model — `MuscleTamagotchiState`

### Groups

Four tamagotchi groups consolidate the existing seven visual regions (from
`muscle_vectors.dart`: `chest`, `abs`, `arms`, `legs`, `shoulders`, `back`):

| Tamagotchi group | Visual regions it drives |
|------------------|--------------------------|
| `chest` | `chest` |
| `core` | `abs`, `back` |
| `arms` | `arms`, `shoulders` |
| `legs` | `legs` |

This mirrors the existing `muscleGroupToRegion` map in
`core/constants/muscle_group_map.dart`, but the avatar now reasons about the
four *groups*, not the fine-grained exercise target names
(`Chest/Triceps/Biceps/Shoulders/Back/Legs/Hamstrings/Core`).

### Values

Each group has a `mass` value constrained to `[0.0, 1.0]`. The four groups
start at the neutral baseline `0.5`.

### Growth

Completing a routine whose exercises target a group increments that group's
mass by a fixed **growth delta** (proposed `0.08`), clamped at `1.0`. Only the
targeted groups change; untargeted groups are untouched.

### Decay

Groups the user has not trained for an elapsed inactive period lose mass
linearly at a **decay rate** (proposed `0.05` per full day), clamped at `0.0`.
Decay requires a persisted **last-activity timestamp** per group so the elapsed
inactive period can be computed when the app resumes.

### Tiers (derived, not stored)

Mass maps to a tier used only for colouring/sizing feedback:

| Tier | Range | Colour |
|------|-------|--------|
| `c` | `mass < 0.33` | Red |
| `b` | `0.33 <= mass < 0.66` | Yellow |
| `a` | `0.66 <= mass < 0.9` | Green |
| `s` | `mass >= 0.9` | Gold |

### API surface (design contract — no implementation)

```dart
enum MuscleTamagotchiGroup { core, arms, chest, legs }

enum MuscleTier { c, b, a, s }

class MuscleTamagotchiState {
  // mass per group, each clamped to [0.0, 1.0]
  double massOf(MuscleTamagotchiGroup group);

  // tier derived from massOf(group)
  MuscleTier tierOf(MuscleTamagotchiGroup group);

  // +delta to the given groups (clamped at 1.0), updates last-activity
  void applyGrowth(Iterable<MuscleTamagotchiGroup> groups);

  // -rate*elapsedDays to inactive groups (clamped at 0.0)
  void applyDecay(Duration elapsed);

  // load/save (SQLite, mirrors ProjectionRepository)
}
```

The class sits alongside the other `ChangeNotifier` controllers in
`core/state/` and follows the existing pattern (no third-party state library).
Persistence follows the M15 projection precedent via a small
`TamagotchiRepository` backed by SQLite (`database_helper.dart`), storing the
four mass values and a per-group last-activity timestamp.

---

## 3. Rendering the avatar — sizing + colour

### 3.1 Group → region mapping

A new constant (e.g. `tamagotchiGroupToRegions`) maps each of the four groups
to its visual region ids (§2). The painter iterates the existing `muscleRegions`
and, for each region, looks up its owning group's mass and tier.

### 3.2 Size = mass

A region's rendered size is driven by a **scale factor** derived from mass:

```
scaleFactor = baseScale * (1 + k * (mass - 0.5))
```

with `k` (proposed `0.5`) controlling how visibly mass changes size, so a
`0.5` group renders at `baseScale` (no change), a `1.0` group bulges larger and
a `0.0` group shrinks. Scaling must happen **around the region's own centroid**
(translate → scale → translate back) so each muscle "bulges" in place rather
than drifting.

### 3.3 Colour = tier

The region fill (and/or stroke) is replaced with the tier colour from §2
instead of the current `AppColors.neutralMuscle`. Selection glow keeps using
the existing primary/accent styling on top.

---

## 4. Implementation approach (choose one, recommend the painter)

Two valid rendering strategies satisfy the contract. **Recommendation: the
dynamic `CustomPaint` approach**, because the existing `InteractiveBodyMap`
already renders every region as a normalised `Path` — the only new work is a
per-region scale matrix and a tier-colour lookup.

### Option A — Dynamic `CustomPaint` paths (recommended)

Keep `InteractiveBodyMap`'s `CustomPaint`/`_BodyMapPainter`. For each region:

1. Compute the region's normalised bounding-box centre.
2. Build a `Matrix4` that translates to the centre, scales by `scaleFactor`,
   translates back, then maps to screen space (existing `_screenPath` logic).
3. Fill/stroke with the tier colour.

`shouldRepaint` compares the injected tamagotchi state (mass/tier changed).

### Option B — `Stack` of scalable layers (`Transform.scale`)

Split the avatar into per-group `Positioned` + `Transform.scale` layers inside a
`Stack`. Each layer paints its group's region paths at full size and is scaled
by `Transform.scale(scale: scaleFactor)`. This is more "widget-composable" but
requires partitioning the single silhouette into group layers and handling the
front/back figure layout manually.

---

## 5. Files

**New**
- `mobile_app/lib/core/state/muscle_tamagotchi_state.dart` — the model: mass,
  growth, decay, tiers (and `MuscleTamagotchiGroup` / `MuscleTier` enums).
- `mobile_app/lib/core/data/tamagotchi_repository.dart` — SQLite persistence
  (mass values + last-activity timestamps).
- `mobile_app/lib/core/constants/tamagotchi_groups.dart` — group→region mapping
  and tier thresholds/colours (or extend `muscle_group_map.dart`).

**Modified**
- `mobile_app/lib/ui/organisms/interactive_body_map.dart` — accept the
  tamagotchi state; render size from mass and colour from tier (§3–§4).
- `mobile_app/lib/ui/organisms/muscle_group_visualizer.dart` — feed the state
  into `InteractiveBodyMap` (and optionally surface a tier legend).
- `mobile_app/lib/core/theme/app_theme.dart` — add the tier colours (Red,
  Yellow, Green reuse existing `danger`/`warning`/`success`; add **Gold**).
- `mobile_app/lib/app.dart` — construct `MuscleTamagotchiState` (+ repository)
  and provide it to the avatar path.

---

## 6. Testability

- **State unit tests** (`muscle_tamagotchi_state_test.dart`): assert the fresh
  baseline is `0.5`; `applyGrowth` raises only the targeted groups and clamps at
  `1.0`; `applyDecay` lowers inactive groups over an elapsed duration and clamps
  at `0.0`; `tierOf` returns `c/b/a/s` across the thresholds.
- **Repository tests**: save a state, reload it, assert mass values (and
  timestamps) are restored.
- **Widget tests** (`interactive_body_map` / visualizer): inject a state with
  contrasting masses and assert a high-mass region paints larger than a low-mass
  one and that each region's fill resolves to the expected tier colour.
- **Feature keys to reuse:** the existing avatar keys; add per-group keys (e.g.
  `tamagotchi_group_chest`, `tamagotchi_group_arms`) and expose each group's
  rendered scale/colour through the widget's public API or a `Key`-addressable
  painter so the Gherkin scenarios can assert size and colour deterministically.

---

## 7. Out of scope

- Animated/morphing transitions between mass values (a snap render is enough
  this milestone; smooth `TweenAnimationBuilder` growth is a follow-up).
- XP / levelling / streak rewards beyond the growth/decay feedback loop.
- Backend tracking of workout consistency — decay is computed from locally
  persisted last-activity timestamps only.
- Replacing `InteractiveBodyMap`'s tap-to-select behaviour (selection is
  preserved; only sizing + colouring change).
