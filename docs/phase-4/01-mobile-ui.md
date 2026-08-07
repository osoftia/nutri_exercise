# PHASE 4 — Flutter Mobile App (Interactive UI, Atomic Design)

> **Author:** [Gemma] (Design & UI/UX Lead)
> **Status:** Draft — pending approval
> **Depends on:** `docs/phase-1/03-atomic-design-ui.md` (tokens + SPG vectors), `docs/phase-1/02-sdd-contracts.md` (contracts)
> **Scope:** The interactive SVG-vector **body map** in Flutter (precise tap gestures on vector paths, "blue gym" glow), rendered through the same Atomic Design hierarchy as Web.

---

## 1. Mobile Design Principles

- **Offline-first visual identity:** the UI always renders from local state; loading/sync states are designed components, never error dumps.
- **Same Atomic Design law as web:** Pages → Templates → Organisms → Molecules → Atoms, with 1:1 mapping to the web inventory so design tokens and component behavior stay consistent cross-platform.
- **Thumb-first ergonomics:** primary actions ≥ 48px, bottom-sheet patterns for secondary flows, safe-area insets respected.

---

## 2. Flutter Component Mapping (from `phase-1/03` §4)

| Layer | Flutter components |
| --- | --- |
| Atoms | `NeButton`, `NeIconButton`, `NeTextField`, `NeSwitch`, `NeChip`, `NeBadge`, `NeLinearProgress`, `NeSpinner`, `NeText`, `NeHeading`, `NeDivider`, `NeSkeleton`, `NeAvatar`, `NeIcon`, `NeVectorPath` |
| Molecules | `NeSearchBar`, `NeStatCard`, `NeMetricRing`, `NeMuscleRegion`, `NeExerciseTile`, `NeMealTile`, `NeFieldGroup`, `NeSegmentControl`, `NeNotificationBadge`, `NeListItem` |
| Organisms | `NeBodyMapCanvas`, `NeExerciseFilterBar`, `NeExerciseCatalog`, `NeWorkoutDayCard`, `NeWeeklySchedulePlanner`, `NeMealMenuSection`, `NeMacroBreakdown`, `NeOnboardingStepper`, `NeAIAssistantPanel`, `NeSyncStatusBanner` |
| Templates | `NeAppShell` (bottom nav), `NeAuthLayout`, `NeOnboardingLayout`, `NeWorkoutLayout`, `NeNutritionLayout`, `NeScheduleLayout` |
| Pages | `LandingPage`, `OnboardingPage`, `ExplorePage`, `WorkoutDetailPage`, `NutritionPage`, `SchedulePage`, `AssistantPage`, `ProfilePage` |

---

## 3. Interactive SVG Body Map (Gemma detail)

### 3.1 Rendering

- Package: `flutter_svg` renders each region path from the shared SPG vector data (`d` attribute, same `0 0 300 600` coordinate space as Web).
- `NeBodyMapCanvas` organism:

```dart
class NeBodyMapCanvas extends StatelessWidget {
  final BodyView view;                       // FRONT | BACK
  final List<MuscleRegion> regions;          // filtered by view
  final Set<MuscleGroupId> selected;
  final ValueChanged<MuscleGroupId> onRegionToggle;
  final ValueChanged<BodyView> onViewChange;
  // builds a Stack: SvgPicture silhouette + per-region NeMuscleRegion overlays
}
```

- **Hit-testing:** each region is wrapped in its own `GestureDetector` sized to the exact path bounding box via `CustomSingleChildLayout`/`Positioned`, so taps map to the region — no dead-zone rectangles covering neighbors. On top of that, a `HitTestBehavior.opaque` translucent hit-surface per path keeps tiny regions tappable on small screens (devices ≥ 320dp verified).

```dart
class NeMuscleRegion extends StatelessWidget {
  final MuscleRegion region;
  final bool isSelected;
  final VoidCallback onTap;

  Widget build(context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          child: SvgPicture.asset('assets/vectors/${region.id}.svg', key: Key(region.id)),
        ),
      );
}
```

### 3.2 Selection States & Glow

| State | Visual |
| --- | --- |
| Idle | fill `color.neutral.muscle` (`#94A3B8`), thin stroke |
| Selected | fill `color.primary.400` (`#60A5FA`) + **pulse glow**: `BoxShadow(color: primary300, blurRadius: 8)` inside an `AnimatedContainer` (300ms ease-out) |
| Disabled (`prefers-reduced-motion` / `MediaQuery.disableAnimations`) | same fill, no animation |
| Focused (keyboard/switch) | 2px `OutlineBorder` in `primary300` |

### 3.3 Interaction Rules (identical to Web §4 of `03-web-ui`)

- Tap region → `onRegionToggle(id)` → selection toggled in store → catalog filtered.
- Tap empty silhouette space → deselect all.
- `NeSegmentControl` in the canvas header toggles FRONT/BACK; regions list re-filters by `view`.
- Selected muscles drive `GET /api/v1/exercises?muscle=…` (debounced via store, see Qwen spec §4).

### 3.4 A11y

- `Semantics(label: 'Chest', button: true, selected: isSelected)` per region; screen readers announce "Chest, 14 exercises".
- `ExcludeSemantics` off the decorative silhouette; semantic taps map to the same handler.

---

## 4. Navigation & Flow

```text
Bottom nav (NeAppShell): Explore | Workouts | Nutrition | Schedule | Profile
Push routes: /onboarding (first-run), /workouts/:id, /assistant, /conflicts (sync review)
```

- First launch → `OnboardingPage` (stepper) → `/explore`.
- Notification tap on a scheduled workout → deep link `/workouts/:id` (see Qwen §3.4).

---

## 5. Visual QA Gates (mobile)

- Golden tests for Atoms/Molecules/Organisms (see QA spec), keyed by theme tokens.
- `MediaQuery.disableAnimations` honored; `flutter analyze` clean.
- Landscape safe-area + notched-device check on Explore (body map scales, no overflow).

---

## 6. Open Decisions

1. Theme: dark only vs. light+dark toggle (carried from Phase 1; affects token `ThemeData`).
2. Vector source: hand-authored SVG assets per muscle vs. generated set from Muscle Wiki dataset.
