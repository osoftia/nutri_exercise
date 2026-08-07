# PHASE 3 — Angular Web App (UI Translation, Atomic Design)

> **Author:** [Gemma] (Design & UI/UX Lead)
> **Status:** Draft — pending approval
> **Depends on:** `docs/phase-1/03-atomic-design-ui.md` (tokens + atomic hierarchy), `docs/phase-1/02-sdd-contracts.md` (API)
> **Scope:** Visual structure of the Web portal, page-by-page composition from the approved Atomic Design hierarchy, and the body-map interaction in the browser.

---

## 1. Web Design Principles

- **Online-first web:** full experience assumes network; degraded states (offline banner, skeleton loaders) still designed.
- **Atomic Design as the law:** Pages import Templates only; Templates compose Organisms; Organisms compose Molecules; Molecules compose Atoms. No atom-to-page leaks.
- **Design tokens** (`phase-1/03` §2) shipped as CSS custom properties consumed by every component.
- **Responsive:** desktop-first at 1280px; 3 breakpoints — mobile < 768, tablet < 1024, desktop ≥ 1024. Body map adapts by scaling the shared `0 0 300 600` viewBox.

---

## 2. Page Composition Map (approved hierarchy → routed pages)

```text
Landing (/)            -> AppShellTemplate > AuthTemplate (hero + form)
Onboarding (/onboarding)-> AppShellTemplate > OnboardingTemplate > OnboardingStepper
                           (FieldGroups, SegmentControls, ProgressBar)
Explore (/explore)     -> AppShellTemplate > WorkoutTemplate
                           > [BodyMapCanvas] + ExerciseFilterBar + ExerciseCatalog
Workout (/workouts/:id)-> AppShellTemplate > WorkoutTemplate > WorkoutDayCard
Nutrition (/nutrition) -> AppShellTemplate > NutritionTemplate > MealMenuSection + MacroBreakdown
Schedule (/schedule)   -> AppShellTemplate > ScheduleTemplate > WeeklySchedulePlanner
Assistant (/assistant) -> AppShellTemplate > WorkoutTemplate > AIAssistantPanel
Profile (/profile)     -> AppShellTemplate > AppShellTemplate > StatCards + Forms
```

### 2.1 Explore page — body-map driven layout

```text
+--------------------------------------------------------------+
| AppBar: brand | search | sync-badge | avatar                  |
+--------------------------------------------------------------+
| [BodyMapCanvas (FRONT|BACK toggle, SVG silhouette)]  | Filters|
|  - region tap -> pulse glow + select                        | [chip list: muscle, equipment, difficulty]
|  - empty-space tap -> clear                                 | [Reset]
|--------------------------------------------------------------|
| ExerciseCatalog (virtualized list of ExerciseTiles)          |
|   sorted by selected muscles; shows sets/reps/equipment      |
+--------------------------------------------------------------+
```

- Default view: **FRONT**. Toggle in the canvas header flips to BACK (same component, `view` input).
- Selection state lifted to the page (via store); catalog queries the API on every committed selection (debounced 300ms).
- Loading: `Skeleton` tiles in catalog; empty state with primary illustration.

---

## 3. Component Inventory (per layer)

### 3.1 Atoms (`src/app/atoms`)

| Component | Output |
| --- | --- |
| `app-button` | all variants (primary/ghost/text), sizes, disabled, loading |
| `app-icon-button` | icon-only, aria-label required |
| `app-input` | text/email/number, error state |
| `app-toggle`, `app-switch` | boolean controls |
| `app-chip` | selectable filter chip with check state |
| `app-badge` | counts, dot indicators |
| `app-progress-bar`, `app-spinner` | progress + loading |
| `app-skeleton` | shimmer blocks |
| `app-avatar` | user avatar |
| `app-icon` | icon set incl. muscle glyphs |
| `app-text`, `app-heading` | typography scale |
| `app-vector-path` | renders one SVG path region (shared with body map) |

### 3.2 Molecules (`src/app/molecules`)

| Component | Notes |
| --- | --- |
| `app-search-bar` | input + icon + clear |
| `app-stat-card` | kcal/macros with caption |
| `app-metric-ring` | SVG ring progress |
| `app-muscle-region` | path + label + glow wrapper (feeds BodyMapCanvas) |
| `app-exercise-tile` | name, muscles chips, sets/reps, equipment |
| `app-meal-tile` | title, kcal, macros mini-bars |
| `app-field-group` | label + input + validation message |
| `app-segment-control` | FRONT/BACK toggle, scope toggles |
| `app-notification-badge` | offline/pending sync |
| `app-list-item` | generic row |

### 3.3 Organisms (`src/app/organisms`)

| Organism | Responsibilities |
| --- | --- |
| `app-body-map-canvas` | SVG silhouette, FRONT/BACK toggle, region selection, pulse glow, `aria` labels, empty-space deselect |
| `app-exercise-filter-bar` | chip filters wired to store |
| `app-exercise-catalog` | paginated/virtualized list, skeletons, empty state |
| `app-workout-day-card` | day header, ordered exercise list, per-exercise completion checkbox |
| `app-weekly-schedule-planner` | weekday grid, time inputs, notification toggle |
| `app-meal-menu-section` | breakfast/lunch/dinner + snack |
| `app-macro-breakdown` | ring + bar per macro |
| `app-onboarding-stepper` | wizard steps, progress, validation between steps |
| `app-ai-assistant-panel` | chat list, input, offline `NETWORK_REQUIRED` banner |
| `app-sync-status-banner` | online/offline/queued/conflict review link |

### 3.4 Templates & Pages

Templates: `app-shell` (sidebar nav + outlet), `app-auth-layout`, `app-onboarding-layout`, `app-workout-layout`, `app-nutrition-layout`, `app-schedule-layout`.

Pages (routes from §2): `LandingPage`, `OnboardingPage`, `ExplorePage`, `WorkoutDetailPage`, `NutritionPage`, `SchedulePage`, `AssistantPage`, `ProfilePage`.

---

## 4. Body Map in the Browser (Gemma detail)

- Single `BodyMapCanvas` organism:
  - Renders `<svg viewBox="0 0 300 600">` with a `FRONT` or `BACK` region group.
  - Each region = `<path [attr.d]="region.d" app-muscle-region>`.
  - Selected regions get class `is-selected` → CSS `fill: var(--color-primary-400)` + animated `filter: drop-shadow(0 0 8px var(--color-primary-300))` (300ms ease-out, disabled under `prefers-reduced-motion`).
  - Hit area = path outline; keyboard: each path is a `<g tabindex="0" role="button">` with `aria-pressed`.
- Coordinates data model = `MuscleRegion { id, label, d, view, fill }`, loaded once from `GET /api/v1/muscles` and cached (contract `phase-1/02` §3.3).

---

## 5. Visual QA Gates (web)

- Storybook for every Atom/Molecule/Organism with theme tokens; Percy visual snapshots in CI.
- Lighthouse budget: LCP < 2.5s, CLS < 0.1 on Explore page (virtualized catalog + lazy route modules).
- Contrast AA verified via token palette; a11y lint (`eslint-plugin-jsx-a11y`-equivalent for Angular templates).

---

## 6. Open Decisions

1. Dark theme only, or light theme as default with dark toggle? (Phase 1 open — affects token file + `prefers-color-scheme`)
2. Vector asset source: hand-authored SVG paths vs. generated from a Muscle Wiki dataset.
