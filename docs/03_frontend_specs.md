# FRONTEND SPEC — Angular Web + Flutter Mobile (Multi-Agent Collaboration Log)

> **Orchestrator:** Multi-Agent (Gemma & Qwen)
> **Status:** Draft — pending approval
> **Depends on:** `docs/phase-1/03-atomic-design-ui.md` (tokens + SPG vectors), `docs/phase-1/02-sdd-contracts.md` (API contracts), `docs/phase-3/01-web-ui.md`, `docs/phase-3/02-web-logic-tests.md`, `docs/phase-4/01-mobile-ui.md`
> **Scope:** Consolidated cross-platform frontend specification. A live collaboration log between **[Gemma]** (Design & UI/UX Lead) and **[Qwen]** (Frontend Logic & QA Lead), covering the Angular web dashboard and the Flutter mobile app with its interactive SVG body map.
> **Constraint:** This document is **structural only** — no raw programmatic implementation. Component mapping, contracts, and ownership are specified; codebases consume this spec.

---

## SECTION 1: ANGULAR WEB APP ARCHITECTURE

### 1.1 [Gemma] — Atomic Design Structure for the Web Dashboard

**Design mandate.** The web dashboard is an *online-first* experience rendered from the shared design tokens (`phase-1/03` §2). The Atomic Design law is non-negotiable: **Pages import Templates; Templates compose Organisms; Organisms compose Molecules; Molecules compose Atoms.** No atom-to-page leaks. The two priority flows are **User Onboarding** and **Daily Menus**.

#### 1.1.1 Atoms (indivisible primitives for onboarding + menus)

| Atom | Component | Used by flow | Notes |
| --- | --- | --- | --- |
| Button | `app-button` | Both | primary/ghost/text variants; loading + disabled states |
| Input | `app-input` | Onboarding | numeric metric fields (weight, height, age); step-aware |
| SegmentControl | `app-segment-control` | Onboarding | gender/activity-level segmented pickers |
| Toggle | `app-toggle` | Onboarding | optional metrics (e.g., target adjustments) |
| Chip | `app-chip` | Both | goal tags (fat loss / muscle gain / maintenance) |
| ProgressBar | `app-progress-bar` | Onboarding | stepper progress |
| StatCard | `app-stat-card` | Menus | kcal / macro totals per meal |
| MetricRing | `app-metric-ring` | Menus | daily calorie ring vs. BMR/TDEE |
| Typography | `app-text`, `app-heading` | Both | full type scale from tokens |
| Divider | `app-divider` | Menus | meal section separators |
| Skeleton | `app-skeleton` | Menus | menu loading placeholders |
| Badge | `app-badge` | Menus | macro distribution counts |

#### 1.1.2 Molecules (composed atoms)

| Molecule | Component | Used by flow | Composition |
| --- | --- | --- | --- |
| FieldGroup | `app-field-group` | Onboarding | label + `app-input` + validation message |
| GoalSelector | `app-goal-selector` | Onboarding | `app-segment-control` + `app-chip` goal tags |
| MealTile | `app-meal-tile` | Menus | title + `app-stat-card` kcal + macro mini-bars |
| MacroBar | `app-macro-bar` | Menus | per-macro `app-progress-bar` + `app-badge` |
| DaySwitcher | `app-day-switcher` | Menus | day chips + arrows to page through menu days |
| SummaryPanel | `app-summary-panel` | Both | `app-metric-ring` + `app-stat-card` cluster |

#### 1.1.3 Organisms (feature sections)

| Organism | Component | Used by flow | Responsibilities |
| --- | --- | --- | --- |
| OnboardingStepper | `app-onboarding-stepper` | Onboarding | wizard steps, per-step validation, final submit |
| BodyMetricsForm | `app-body-metrics-form` | Onboarding | collects metrics → computes BMR/TDEE via server |
| GoalsForm | `app-goals-form` | Onboarding | goal + activity + dietary restrictions |
| ResultsReview | `app-results-review` | Onboarding | presents computed routine/menu summary before confirm |
| MealMenuSection | `app-meal-menu-section` | Menus | breakfast / lunch / dinner / snack grids |
| MacroBreakdown | `app-macro-breakdown` | Menus | ring + per-macro bars |
| DailyMenuCard | `app-daily-menu-card` | Menus | full day menu + totals + swap-in suggestions |

#### 1.1.4 Templates & Pages

- **Templates:** `app-auth-layout`, `app-onboarding-layout` (stepper shell), `app-nutrition-layout` (menu shell).
- **Pages:** `LandingPage` (`/`), `OnboardingPage` (`/onboarding`), `NutritionPage` (`/nutrition`).
- **Visual QA:** menu macros must balance to daily targets with 5% tolerance; onboarding stepper never blocks on a field without inline `app-field-group` error messaging.

---

### 1.2 [Qwen] — Angular Routing, Services (Auth, Diet, Routine) & Testing Strategy

**Logic mandate.** Consume the API contracts from `phase-1/02` through typed services behind the root `ApiHttpClient`. State lives in **NgRx `signalStore`** per feature (approved in `phase-3/02`). Routing is lazy + guarded.

#### 1.2.1 Routing Structure

| Route | Component (lazy) | Guards |
| --- | --- | --- |
| `/` | `LandingPage` | `GuestGuard` |
| `/onboarding` | `OnboardingPage` | `AuthGuard` |
| `/nutrition` | `NutritionPage` | `AuthGuard` + `OnboardingGuard` |
| `/explore` | `ExplorePage` | `AuthGuard` + `OnboardingGuard` |
| `/workouts/:id` | `WorkoutDetailPage` | `AuthGuard` + `OnboardingGuard` |
| `/schedule` | `SchedulePage` | `AuthGuard` + `OnboardingGuard` |
| `/assistant` | `AssistantPage` | `AuthGuard` + `OnboardingGuard` |
| `/profile` | `ProfilePage` | `AuthGuard` |
| `**` | redirect → `/` | — |

- Feature modules lazy-loaded; `PreloadAllModules` after first paint, Explore prefetched.
- Guards as functional `CanActivateFn` reading store signals (approved pattern, `phase-3/02` §2).

#### 1.2.2 Required Services

| Service | Responsibility | Key methods |
| --- | --- | --- |
| `AuthService` | JWT login/logout, token refresh, session restore | `login()`, `logout()`, `refresh()` |
| `DietService` | Daily menu generation + retrieval (server-computed BMR/TDEE/macros) | `generateMenu()`, `getDay()`, `swapMeal()` |
| `RoutineService` | Daily workout plan generation + retrieval | `generateRoutine()`, `getWeek()`, `getDay()` |
| `MuscleService` | SPG vector regions (cached, 24h TTL) | `getRegions()`, `filterByView()` |

- All services wrap the envelope-aware `ApiHttpClient`; errors flow through the typed `ErrorInterceptor` (maps `NETWORK_REQUIRED`, 4xx/5xx → `ApiError`).
- Onboarding submits once via `ProfileStore`; `DietService` + `RoutineService` are then called in parallel and their results land in `NutritionStore` / `WorkoutStore`.

#### 1.2.3 Jasmine/Karma Testing Strategy

- **Runner:** Karma + Jasmine headless (`ChromeHeadless`), `jasmine-marbles` for RxJS, `ng-mocks` `provideMock`, `HttpTestingController` for HTTP.
- **Tiers:**
  1. **Store tests** (`*.store.spec.ts`) — signal state transitions (e.g., `generateMenu` → `menu` populated, `loading` toggled; `selectMuscle` toggle semantics).
  2. **Service tests** (`*.service.spec.ts`) — request/response mapping, envelope unwrapping, error mapping, cache TTL on `MuscleService`.
  3. **Component tests** — `BodyMetricsForm` validates before emit; `MealMenuSection` renders `MealTile`s from mocked `NutritionStore`; a11y attributes asserted (`aria` labels, `aria-pressed`).
  4. **Guard tests** — `OnboardingGuard` redirects to `/onboarding` when `hasProfile()` is false.
- **Coverage gate:** statement ≥ 80% across `app/`; CI runs `ng test --no-watch --browsers=ChromeHeadless --code-coverage` on every PR touching `web/**`.

---

## SECTION 2: FLUTTER MOBILE APP ARCHITECTURE

### 2.1 [Gemma] — Interactive SVG Vector Body Map ("Blue Gym" Style)

**Design mandate.** The signature mobile feature: a vector human silhouette where each muscle group is a precise tappable region. Styling follows the "blue gym" language — idle muscles in neutral slate, selected muscles in glowing primary blue.

#### 2.1.1 SVG Path Structure

- Single shared coordinate space `0 0 300 600` (identical to Web) so FRONT/BACK never misalign.
- One **asset per muscle region** per view: `assets/vectors/front/{CHEST,BICEPS,...}.svg` and `assets/vectors/back/{LATS,TRAPS,...}.svg`, each drawn as a closed path `M…Z` in that shared space.
- Regions are **self-contained paths** (no shared parent path), enabling per-region tinting, glow, and independent hit-testing.
- A decorative silhouette base layer (single neutral path) sits *behind* all regions and is `ExcludeSemantics` (non-interactive).

```text
NeBodyMapCanvas (organism)
 ├── base silhouette (decorative, ExcludeSemantics)
 ├── per-region overlay: NeMuscleRegion { path asset + GestureDetector + glow }
 └── header: NeSegmentControl (FRONT | BACK)
```

#### 2.1.2 Tappable Region Layout (Gemma detail)

- `NeBodyMapCanvas` is a `Stack`: `SvgPicture` silhouette + positioned `NeMuscleRegion` overlays.
- Each `NeMuscleRegion` maps one muscle id → its SVG path asset; the tap surface is the path's precise bounds with `HitTestBehavior.opaque`, so neighboring regions never overlap their hit areas.
- **Interaction rules (identical to Web):**
  - Tap region → toggle selection (multi-select allowed).
  - Tap empty silhouette space → deselect all.
  - FRONT/BACK toggle re-filters the region list from the same SPG vector source.
- **States:** Idle = `color.neutral.muscle` (#94A3B8) fill; **Selected** = `color.primary.400` (#60A5FA) fill + 300ms pulse glow (`BoxShadow` blur 8, eased out); Disabled/Focused states respect `MediaQuery.disableAnimations` and 2px outline in `primary300`.
- **A11y:** `Semantics(label: 'Chest', button: true, selected: …)` per region, announcing "Chest, 14 exercises"; decorative base excluded.
- Selected muscles drive the exercise catalog query (`GET /api/v1/exercises?muscle=…`), debounced in the store — the canvas only emits `onRegionToggle(id)`, it owns no data.

---

### 2.2 [Qwen] — Flutter State Management, SQLite Offline Repository & AI Interceptor

**Logic mandate.** Mobile is **offline-first**: every screen renders from local state; the network is an optimization. State handling and offline persistence are fully separated from UI.

#### 2.2.1 State Management — Riverpod (recommended) with BLoC alternatives

- **Decision:** **Riverpod (v2)** — compile-safe providers, no BuildContext in logic, trivial testability. BLoC remains acceptable for teams preferring streams; the contract below is state-agnostic.

| Store | State | Responsibilities |
| --- | --- | --- |
| `authProvider` | user, token, session | login/logout/refresh |
| `profileProvider` | profile, hasProfile, tdee | onboarding submit, refresh |
| `bodyMapProvider` | view, selectedMuscles, regions | toggle region, flip FRONT/BACK |
| `catalogProvider` | exercises, loading | filter by selected muscles (debounced) |
| `routineProvider` | weekly plan, days | generate/load from SQLite first |
| `dietProvider` | menu, macros | generate/load from SQLite first |
| `scheduleProvider` | schedules | CRUD + notification scheduling |
| `syncProvider` | status, pendingCount | offline queue + reconciliation |
| `aiAssistantProvider` | messages, offline | interceptor-driven chat |

#### 2.2.2 SQLite Offline Repository

- **Engine:** `sqflite` + `drift` code-gen for typed tables and migrations; a `OfflineRepository` abstraction with `RemoteDataSource` (API) and `LocalDataSource` (SQLite) implementations.
- **Repository read strategy:** read local → trigger sync → stream updates; writes go to local queue and are flushed when connectivity returns.
- **Tables:** `profiles`, `muscle_regions`, `exercises`, `routines`, `routine_days`, `menu_days`, `meals`, `schedule_entries`, `sync_queue`, `conflicts`.
- **Sync semantics:** monotonic `updatedAt` per row; `sync_queue` holds offline writes keyed by entity + action; conflict resolution surfaces a review list (human-in-the-loop) instead of silent overwrite.
- **Cache policies:** `muscle_regions` immutable (refresh only on version bump); `exercises` TTL 24h; user-generated rows never evicted.

#### 2.2.3 AI Assistant Interceptor Logic

- A dedicated **network interceptor** wraps every AI request (dio interceptor / repository guard):
  1. Request enters → check `connectivity` + `OfflineRepository` availability.
  2. **Offline** → do NOT hit the network; produce a typed `AIUnavailableResult` (`NETWORK_REQUIRED`) → UI renders the offline banner in `NeAIAssistantPanel` (no crash, no stack dump).
  3. **Online** → forward request; on failure, classify (timeout/5xx) → fall back to the same `NETWORK_REQUIRED` surfaced state and queue nothing (idempotent retry).
  4. **Intercepted while typing** → debounce; pending messages render locally with a "pending" badge until resolved.
- The exact same contract drives the Web `AssistantStore.send()` so behavior is cross-platform identical.

#### 2.2.4 Local Notifications

- `flutter_local_notifications` schedules weekly routine reminders; tapping a notification deep-links to `/workouts/:id` (route guarded by `OnboardingGuard`).

---

## SECTION 3: ATOMIC DESIGN COMPONENT MANIFEST

### 3.1 [Gemma & Qwen Collaborative] — Cross-Platform Component Manifest

> Consolidated ownership table. **Design owner** = [Gemma]; **Logic owner** = [Qwen]; **Both** = collaborative (shared contract). Components are mapped 1:1 across Angular and Flutter.

| Component | Angular (web) | Flutter (mobile) | Layer | Design owner | Logic owner | Cross-platform contract |
| --- | --- | --- | --- | --- | --- | --- |
| Button | `app-button` | `NeButton` | Atom | [Gemma] | [Qwen] | Variants, sizes, loading/disabled states |
| Input | `app-input` | `NeTextField` | Atom | [Gemma] | [Qwen] | Validation states, keyboard types |
| SegmentControl | `app-segment-control` | `NeSegmentControl` | Atom | [Gemma] | [Qwen] | FRONT/BACK, scope toggles |
| Toggle / Switch | `app-toggle` | `NeSwitch` | Atom | [Gemma] | [Qwen] | Boolean control semantics |
| Chip | `app-chip` | `NeChip` | Atom | [Gemma] | [Qwen] | Selectable filter state |
| Badge | `app-badge` | `NeBadge` | Atom | [Gemma] | [Qwen] | Counts, dot indicators |
| ProgressBar | `app-progress-bar` | `NeLinearProgress` | Atom | [Gemma] | [Qwen] | Progress semantics |
| MetricRing | `app-metric-ring` | `NeMetricRing` | Molecule | [Gemma] | [Qwen] | Daily progress SVG ring |
| Skeleton | `app-skeleton` | `NeSkeleton` | Atom | [Gemma] | [Qwen] | Loading placeholder |
| Typography | `app-text` / `app-heading` | `NeText` / `NeHeading` | Atom | [Gemma] | [Qwen] | Full type scale |
| VectorPath / MuscleRegion | `app-muscle-region` | `NeMuscleRegion` | Molecule | [Gemma] | [Qwen] | SPG path + tap + glow contract |
| FieldGroup | `app-field-group` | `NeFieldGroup` | Molecule | [Gemma] | [Qwen] | Label + input + error |
| StatCard | `app-stat-card` | `NeStatCard` | Molecule | [Gemma] | [Qwen] | kcal / macro display |
| SearchBar | `app-search-bar` | `NeSearchBar` | Molecule | [Gemma] | [Qwen] | Input + icon + clear |
| ExerciseTile | `app-exercise-tile` | `NeExerciseTile` | Molecule | [Gemma] | [Qwen] | Sets/reps/equipment row |
| MealTile | `app-meal-tile` | `NeMealTile` | Molecule | [Gemma] | [Qwen] | Title + kcal + macro bars |
| BodyMapCanvas | `app-body-map-canvas` | `NeBodyMapCanvas` | Organism | [Gemma] | [Qwen] | FRONT/BACK + region selection + glow |
| ExerciseFilterBar | `app-exercise-filter-bar` | `NeExerciseFilterBar` | Organism | [Gemma] | [Qwen] | Muscle/equipment/difficulty chips |
| ExerciseCatalog | `app-exercise-catalog` | `NeExerciseCatalog` | Organism | [Gemma] | [Qwen] | List + skeleton + empty state |
| OnboardingStepper | `app-onboarding-stepper` | `NeOnboardingStepper` | Organism | [Gemma] | [Qwen] | Wizard steps + validation |
| BodyMetricsForm | `app-body-metrics-form` | `NeBodyMetricsForm` | Organism | [Gemma] | [Qwen] | Metrics → BMR/TDEE flow |
| MealMenuSection | `app-meal-menu-section` | `NeMealMenuSection` | Organism | [Gemma] | [Qwen] | Breakfast/lunch/dinner/snack |
| DailyMenuCard | `app-daily-menu-card` | `NeDailyMenuCard` | Organism | [Gemma] | [Qwen] | Day menu + totals + swaps |
| MacroBreakdown | `app-macro-breakdown` | `NeMacroBreakdown` | Organism | [Gemma] | [Qwen] | Ring + per-macro bars |
| WorkoutDayCard | `app-workout-day-card` | `NeWorkoutDayCard` | Organism | [Gemma] | [Qwen] | Day header + exercise list |
| WeeklySchedulePlanner | `app-weekly-schedule-planner` | `NeWeeklySchedulePlanner` | Organism | [Gemma] | [Qwen] | Weekday grid + notification toggle |
| AIAssistantPanel | `app-ai-assistant-panel` | `NeAIAssistantPanel` | Organism | [Gemma] | [Qwen] | Chat + `NETWORK_REQUIRED` offline banner |
| SyncStatusBanner | `app-sync-status-banner` | `NeSyncStatusBanner` | Organism | [Gemma] | [Qwen] | online/offline/queued/conflict states |
| AppShell | `app-shell` | `NeAppShell` | Template | [Gemma] | [Qwen] | Nav + content outlet (bottom nav mobile) |
| AuthLayout | `app-auth-layout` | `NeAuthLayout` | Template | [Gemma] | [Qwen] | Split hero + form |
| OnboardingLayout | `app-onboarding-layout` | `NeOnboardingLayout` | Template | [Gemma] | [Qwen] | Stepper shell |
| WorkoutLayout | `app-workout-layout` | `NeWorkoutLayout` | Template | [Gemma] | [Qwen] | Workout page shell |
| NutritionLayout | `app-nutrition-layout` | `NeNutritionLayout` | Template | [Gemma] | [Qwen] | Menu page shell |
| ScheduleLayout | `app-schedule-layout` | `NeScheduleLayout` | Template | [Gemma] | [Qwen] | Schedule page shell |

### 3.2 Ownership Rules

1. **[Gemma]** owns every visual contract: tokens, states, a11y semantics, motion, and the SVG/vector path geometry. Any change to a visual token or path requires Gemma approval.
2. **[Qwen]** owns every logic contract: store/state shape, service/repository APIs, sync semantics, interceptor behavior, and test coverage. Any change to data flow requires Qwen approval.
3. **Both** must co-sign any component that spans UI and data (e.g., `BodyMapCanvas` — Gemma defines the path/tap/glow contract, Qwen defines the `selected`/`view` state that feeds it).
4. **Cross-platform parity:** a component is only "Done" when Angular and Flutter both implement the shared manifest row and pass their respective QA gates (Percy/Storybook web, golden tests mobile, plus Jasmine/Riverpod unit suites).

---

## 4. Approved Decisions & Open Decisions

**Approved (Frontend gate):**
1. Mobile state management: **Riverpod** (BLoC acceptable via documented adapter).
2. Body map: single shared SVG coordinate space `0 0 300 600`, per-region self-contained paths, FRONT/BACK toggle in `BodyMapCanvas`.
3. Offline-first mobile: SQLite (`drift`) behind an `OfflineRepository`; AI requests intercepted to a typed `NETWORK_REQUIRED` state.

**Open:**
1. Theme: dark-only vs. light+dark toggle (carried from Phase 1/3).
2. Vector asset source: hand-authored SVG per muscle vs. generated set from a Muscle Wiki dataset.
