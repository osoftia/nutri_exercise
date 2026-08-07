# PHASE 1 — UI & Atomic Design (SPG Body Map + Design System)

> **Author:** [Gemma] (Design & UI/UX Lead)
> **Status:** Draft — pending approval
> **Scope:** SPG vector structure for the interactive body map, design tokens, and the strict Atomic Design hierarchy for both **Angular (Web)** and **Flutter (Mobile)**.

---

## 1. Design Vision

- **Theme:** "Blue Gym" — energetic athletic feel built on a **blue primary scale** with dark surfaces and high-contrast accents.
- **Tone:** clean, confident, data-dense but approachable. Rounded-but-not-cutesy cards, strong whitespace, clear hierarchy.
- **Signature feature:** the interactive **Muscle Wiki style body map** — a vector human silhouette where each muscle group is a tappable region that lights up with a "blue gym" glow on selection.

---

## 2. Design Tokens (SPG Foundation)

### 2.1 Color Palette

| Token | Value | Usage |
| --- | --- | --- |
| `color.primary.500` | `#3B82F6` | primary actions, selected muscles |
| `color.primary.400` | `#60A5FA` | hover / active state, glow |
| `color.primary.300` | `#93C5FD` | selected muscle highlight |
| `color.surface.900` | `#0F172A` | app background (dark) |
| `color.surface.800` | `#1E293B` | cards |
| `color.surface.700` | `#334155` | inputs / dividers |
| `color.text.high` | `#F8FAFC` | headings |
| `color.text.medium` | `#CBD5E1` | body |
| `color.text.low` | `#64748B` | hints, disabled |
| `color.accent` | `#F97316` | CTA highlights (warm vs. cool balance) |
| `color.success` | `#22C55E` | completed workout |
| `color.warning` | `#EAB308` | sync pending |
| `color.danger` | `#EF4444` | errors, NETWORK_REQUIRED |
| `color.neutral.muscle` | `#94A3B8` | idle muscle silhouette |

### 2.2 Typography

| Token | Spec |
| --- | --- |
| Font family | Inter (UI) + system fallback |
| `text.h1` | 32/40, SemiBold |
| `text.h2` | 24/32, SemiBold |
| `text.h3` | 20/28, Medium |
| `text.body` | 16/24, Regular |
| `text.caption` | 12/16, Regular |
| `text.label` | 14/20, Medium (uppercase, letter-spacing 0.5) |

### 2.3 Spacing / Radius / Motion

| Token | Value |
| --- | --- |
| Spacing scale | 4, 8, 12, 16, 24, 32, 48 |
| `radius.sm / md / lg` | 8 / 12 / 20 |
| Motion | 150–250ms, ease-out; body-map selection uses a 300ms "pulse glow" |
| Elevation | soft shadows `0 4 12 rgba(15,23,42,0.4)` |

---

## 3. SPG Vector Representation — Interactive Body Map

### 3.1 What is an SPG Vector here

An **SPG (System Pattern Guideline) vector** encodes a component's spatial pattern as a set of named, tappable vector paths + metadata. It is the single source of truth consumed identically by Angular (inline SVG) and Flutter (custom `CustomPainter`/`flutter_svg`).

```text
BodyMap
 ├── view: "FRONT" | "BACK"  (two silhouettes, toggleable)
 └── regions[]
      └── muscleGroup (id) -> svgPath (d attribute) + meta
```

### 3.2 Vector Data Contract (matches API `/api/v1/muscles`)

```json
{
  "view": "FRONT",
  "regions": [
    {
      "id": "CHEST",
      "label": "Chest",
      "d": "M120 150 C … Z",            // SVG path (same coordinate space per view)
      "fill": "#3B82F6",
      "neighbors": ["SHOULDERS", "BICEPS", "CORE"],
      "exerciseCount": 14
    }
  ]
}
```

- Every region uses the **same 0 0 300 600 viewBox** so switching views/muscles never breaks alignment.
- `neighbors` powers the "muscle chain" highlight (training synergists).

### 3.3 Interaction Spec (both platforms)

| State | Visual | Behavior |
| --- | --- | --- |
| Idle | `color.neutral.muscle` fill, subtle stroke | — |
| Hover (desktop) | lighten 15%, cursor pointer | show tooltip label + count |
| Selected | `color.primary.400` fill + 300ms pulse glow (drop-shadow / shadow) | filter exercise list; multi-select allowed |
| Focused (keyboard) | 2px outline `color.primary.300` | a11y requirement |
| Disabled | 40% opacity | no match in filtered set |

- Hit area = the vector path itself (precise taps, no bounding-box overreach).
- Tap on empty silhouette space → deselect all.
- A `selectedMuscles` state (set of `id`s) drives the exercise catalog query (`GET /api/v1/exercises?muscle=…`).

---

## 4. Atomic Design Hierarchy

> Atoms → Molecules → Organisms → Templates → Pages. Same 5 levels on both platforms, shared token language.

### 4.1 ATOMS (indivisible primitives)

| Atom | Angular (web) | Flutter (mobile) |
| --- | --- | --- |
| `Button` | `app-button` | `NeButton` |
| `IconButton` | `app-icon-button` | `NeIconButton` |
| `Input` | `app-input` | `NeTextField` |
| `Toggle` | `app-toggle` | `NeSwitch` |
| `Chip` (filter tags) | `app-chip` | `NeChip` |
| `Badge` | `app-badge` | `NeBadge` |
| `ProgressBar` | `app-progress-bar` | `NeLinearProgress` |
| `Spinner` | `app-spinner` | `NeSpinner` |
| `Typography` (`Text`, `Heading`) | `app-text`, `app-heading` | `NeText`, `NeHeading` |
| `Divider` | `app-divider` | `NeDivider` |
| `Skeleton` (loading) | `app-skeleton` | `NeSkeleton` |
| `Avatar` | `app-avatar` | `NeAvatar` |
| `Icon` (system + muscle glyph) | `app-icon` | `NeIcon` |
| `VectorPath` (SVG path atom) | `app-vector-path` | `NeVectorPath` |

### 4.2 MOLECULES (composed atoms)

| Molecule | Angular | Flutter |
| --- | --- | --- |
| `SearchBar` | `app-search-bar` | `NeSearchBar` |
| `StatCard` (kcal / macros) | `app-stat-card` | `NeStatCard` |
| `MetricRing` (daily progress) | `app-metric-ring` | `NeMetricRing` |
| `MuscleRegion` (path + label + glow) | `app-muscle-region` | `NeMuscleRegion` |
| `ExerciseTile` | `app-exercise-tile` | `NeExerciseTile` |
| `MealTile` | `app-meal-tile` | `NeMealTile` |
| `FieldGroup` (label + input + error) | `app-field-group` | `NeFieldGroup` |
| `SegmentControl` | `app-segment-control` | `NeSegmentControl` |
| `NotificationBadge` (offline/sync) | `app-notification-badge` | `NeNotificationBadge` |
| `ListItem` | `app-list-item` | `NeListItem` |

### 4.3 ORGANISMS (feature sections)

| Organism | Angular | Flutter |
| --- | --- | --- |
| `BodyMapCanvas` (view + regions + toggle) | `app-body-map-canvas` | `NeBodyMapCanvas` |
| `ExerciseFilterBar` (muscle chips + equipment) | `app-exercise-filter-bar` | `NeExerciseFilterBar` |
| `ExerciseCatalog` (list + search) | `app-exercise-catalog` | `NeExerciseCatalog` |
| `WorkoutDayCard` (day header + exercise list) | `app-workout-day-card` | `NeWorkoutDayCard` |
| `WeeklySchedulePlanner` | `app-weekly-schedule-planner` | `NeWeeklySchedulePlanner` |
| `MealMenuSection` (breakfast/lunch/dinner) | `app-meal-menu-section` | `NeMealMenuSection` |
| `MacroBreakdownChart` | `app-macro-breakdown` | `NeMacroBreakdown` |
| `OnboardingStepper` (metrics wizard) | `app-onboarding-stepper` | `NeOnboardingStepper` |
| `AIAssistantPanel` | `app-ai-assistant-panel` | `NeAIAssistantPanel` |
| `SyncStatusBanner` (offline/pending) | `app-sync-status-banner` | `NeSyncStatusBanner` |

### 4.4 TEMPLATES (page layouts)

| Template | Angular | Flutter |
| --- | --- | --- |
| `AppShellTemplate` (nav + content outlet) | `app-shell` | `NeAppShell` |
| `AuthTemplate` (split hero + form) | `app-auth-layout` | `NeAuthLayout` |
| `OnboardingTemplate` | `app-onboarding-layout` | `NeOnboardingLayout` |
| `WorkoutTemplate` | `app-workout-layout` | `NeWorkoutLayout` |
| `NutritionTemplate` | `app-nutrition-layout` | `NeNutritionLayout` |
| `ScheduleTemplate` | `app-schedule-layout` | `NeScheduleLayout` |

### 4.5 PAGES (routed views)

| Page | Route (Angular) | Route (Flutter) |
| --- | --- | --- |
| Landing/Home | `/` | `/` |
| Onboarding | `/onboarding` | `/onboarding` |
| Exercise Explorer (body map) | `/explore` | `/explore` |
| Workout Detail | `/workouts/:id` | `/workouts/:id` |
| Nutrition | `/nutrition` | `/nutrition` |
| Schedule | `/schedule` | `/schedule` |
| AI Assistant | `/assistant` | `/assistant` |
| Profile/Settings | `/profile` | `/profile` |

---

## 5. Platform-Specific Implementation Notes

### 5.1 Angular (Web)

- Inline SVG rendered per vector region; interaction via `(click)` + pointer events; `aria-label` per path.
- Component library via standalone components + Design Tokens as CSS custom properties.
- State: NgRx (actions for `bodyMap.selectMuscle`, `catalog.load`, `schedule.upsert`).
- PWA shell for caching + online badge (web is online-first).

### 5.2 Flutter (Mobile)

- `flutter_svg` renders the same `d` paths; tap handling via `GestureDetector` with precise path hit-testing; region glow via `BoxShadow`/`AnimatedContainer` (300ms).
- Offline-aware: every organism receives a `ConnectivityState` so the AI panel shows the `NETWORK_REQUIRED` banner instead of crashing.
- Notifications rendered by `flutter_local_notifications` (tapping a schedule notification deep-links to `/workouts/:id`).

---

## 6. Accessibility & Quality Gates

- WCAG 2.1 AA contrast on all tokens; focus rings; `prefers-reduced-motion` disables pulse glow.
- Screen-reader labels for every vector region ("Chest — 14 exercises").
- Visual regression tests (percy/storybook web; golden tests flutter) for each Atom.

---

## 7. Approved Decisions & Open Decisions

**Approved (PHASE 1 gate):**
1. Body map: **single silhouette canvas with FRONT/BACK toggle** (`BodyMapCanvas` organism owns the toggle).

**Open:**
1. Dark theme only, or light theme as default with dark toggle?
2. Vector asset format: hand-authored SVG paths vs. generated from a Muscle Wiki dataset.
