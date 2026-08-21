# Milestone 11 — Main Navigation, Mock Screens & Neumorphic Theming Plan

> **Author:** @Architect
> **Status:** Ready for @Coder implementation (strict TDD)
> **Branch:** `feature/m11-navigation-theming`
> **Contract:** `mobile_app/test/features/m11_navigation.feature`

---

## 1. Scope

Restructure the Flutter `mobile_app` shell around a **4-tab bottom navigation**
(ROUTINES, NUTRITION, SCHEDULE, PROFILE) and introduce:

1. **Montserrat** as the global default typography via the `google_fonts`
   package.
2. A reusable **neumorphic container** widget (soft light/dark shadows) used by
   the bottom navigation bar and cards.
3. **Routing/state** for the 4 main tabs.
4. **Mock data** shown in each tab (hardcoded routine list, dummy nutrition
   plan, schedule calendar view, static user profile).

This milestone is purely presentational: it replaces the current single
"Admin Dashboard" body with a tabbed shell backed by mock content. No
real repository/API wiring is required (that remains for later milestones).

---

## 2. Current state analysis

- **Shell / navigation:** `lib/ui/pages/home_page.dart` renders one body
  (dashboard) and a static `BottomNavBar(currentIndex: 0)`. The existing
  `lib/ui/organisms/bottom_nav_bar.dart` currently declares **5** destinations
  (Dashboard, Routines, Nutrition, Schedule, Profile) using Material 3
  `NavigationBar`.
- **Theme:** `lib/core/theme/app_theme.dart` sets `fontFamily: 'Inter'` with
  a dark `ColorScheme`; `navigationBarTheme` uses `surface900` background and
  a primary-tinted indicator. Cards use `CardThemeData` with `elevation: 0`.
- **Typography:** `lib/ui/atoms/typography.dart` provides app-level heading/
  text widgets (referenced as `AppHeading`, `AppText`, `AppCaption`).

### Gaps to fill (Green phase)
- Replace `fontFamily: 'Inter'` with Montserrat loaded from `google_fonts`.
- Introduce a reusable `NeumorphicContainer` widget.
- Reshape `BottomNavBar` to exactly 4 tabs and restyle it with the
  neumorphic container.
- Replace the single dashboard body with a tabbed shell that routes among 4
  mock screens.

---

## 3. New components

### 3.1 Typography — Montserrat

- Add dependency `google_fonts` to `pubspec.yaml`.
- In `lib/core/theme/app_theme.dart`:
  - Set `fontFamily` to `GoogleFonts.montserrat().fontFamily` (or wire
    `GoogleFonts.montserratTextTheme(...)`).
  - Keep the existing `TextTheme` sizes/weights/tokens; only the family
    changes.
- Because `google_fonts` fetches fonts at runtime, add an offline fallback
  consideration: rely on the package's bundled asset lookup or specify a
  fallback family so tests/widgets resolve deterministically.

### 3.2 Neumorphic container

**`NeumorphicContainer`** (`lib/ui/atoms/neumorphic_container.dart`), a
reusable `StatelessWidget`:

- Props: `child`, `width`/`height` or `constraints`, `borderRadius`
  (default `AppRadius.lg`), `padding`, optional `isPressed`/inset flag.
- Rendering: a `Container` (color = `AppColors.surface800`) wrapped in two
  offset `BoxShadow`s:
  - **light** highlight shadow (top-left, e.g. `AppColors.surface700` at low
    opacity, offset `(-6, -6)`, blur ~12),
  - **dark** shadow (bottom-right, e.g. `AppColors.surface900` at higher
    opacity, offset `(6, 6)`, blur ~12).
- Expose a small design-token block (e.g. `NeumorphicStyles.lightShadow` /
  `NeumorphicStyles.darkShadow` constants) so shadows stay consistent.

### 3.3 Bottom navigation (4 tabs)

Reshape `lib/ui/organisms/bottom_nav_bar.dart`:

- Reduce destinations to exactly 4: **ROUTINES**, **NUTRITION**, **SCHEDULE**,
  **PROFILE** (drop the old "Dashboard" destination).
- Replace the Material `NavigationBar` visual with a `NeumorphicContainer`
  containing the 4 nav items (or keep `NavigationBar` but wrap it in a
  neumorphic container). Selected item uses the primary accent; unselected
  items use `textLow`.
- Keep the existing `currentIndex` / `onDestinationSelected` props so state
  lives in the parent shell.

### 3.4 Shell / routing state

Introduce a tabbed shell (e.g. `lib/ui/pages/main_shell_page.dart`) — or
repurpose `HomePage` — that:

- Holds an `int _currentIndex` (0..3).
- Renders the active tab body in a `Scaffold` body and the
  `BottomNavBar` in `bottomNavigationBar`.
- Defaults to index 0 (Routines).

### 3.5 Mock screens

Four screen widgets under `lib/ui/pages/` (each a `StatelessWidget` that
renders a `NeumorphicContainer`-based card list):

1. **`RoutinesPage`** (`lib/ui/pages/routines_page.dart`)
   - Hardcoded list of routines (weekday + focus + exercise count), e.g.
     "Monday — Push", "Wednesday — Pull", "Friday — Legs".
   - Displayed as neumorphic cards; selecting a card is out of scope (visual
     only).
2. **`NutritionPage`** (`lib/ui/pages/nutrition_page.dart`)
   - Dummy nutrition plan: a few meal rows (breakfast/lunch/dinner) with
     name + calories rendered as neumorphic cards.
3. **`SchedulePage`** (`lib/ui/pages/schedule_page.dart`)
   - A basic calendar view (static current-month grid) with days as
     neumorphic tiles; a hardcoded "session" marker on a few dates.
4. **`ProfilePage`** (`lib/ui/pages/profile_page.dart`)
   - Static user profile: avatar placeholder, name, goal, and a couple of
     stats in neumorphic cards.

Each screen imports `AppTheme` tokens and `NeumorphicContainer` only; no
repository dependencies.

---

## 4. Mocking strategy for tests

- All four screens render **hardcoded** data — no repository/API needed, so no
  repository mocks are required for the widget tests.
- Widget tests assert on **visible text/labels** (tab names, screen headings,
  mock list items) exactly as written in the `.feature` contract.
- Theme is verified by asserting the resolved `ThemeData.fontFamily` equals
  the Montserrat font family and that the bottom navigation uses the
  neumorphic container (e.g. present by key).

---

## 5. TDD Execution Order (for @Coder)

Follow Red → Green strictly. Run `flutter test` (target file) after each step;
`flutter analyze` at the end of Green.

| Step | Test (RED) | Implementation (GREEN) |
|------|-----------|------------------------|
| 0 | (contract) keep `test/features/m11_navigation.feature` as source of truth | — |
| 1 | **Theme font test** `test/theme/app_theme_test.dart`: assert `AppTheme.dark.fontFamily` is the Montserrat family. (RED: still Inter) | Add `google_fonts` dep; update `app_theme.dart` fontFamily to Montserrat. |
| 2 | **Neumorphic container test** `test/ui/neumorphic_container_test.dart`: pump `NeumorphicContainer` and assert it renders with light+dark shadows. (RED: class missing) | Create `NeumorphicContainer` + `NeumorphicStyles`. |
| 3 | **Bottom nav 4-tab test** `test/ui/bottom_nav_bar_test.dart`: render `BottomNavBar` and assert exactly 4 destinations with labels Routines/Nutrition/Schedule/Profile. (RED: has 5, includes Dashboard) | Reshape `BottomNavBar` to 4 tabs, wrap in neumorphic container. |
| 4 | **Shell routing test** `test/features/m11_navigation_widget_test.dart`: pump shell at index 0, assert Routines content; tap each tab, assert respective screen shows; return to Nutrition and assert it persists. (RED: no shell/screens) | Create `MainShellPage` (or rework `HomePage`) + 4 mock screens wired to index state. |
| 5 | **Regression + log + commit**: full `flutter test`, `flutter analyze`, `docs/m11_execution_changes.log`, `git add .` + commit. | — |

---

## 6. Files created / modified (proposal)

```
mobile_app/
├── pubspec.yaml                              # + google_fonts (modified)
├── test/
│   ├── features/
│   │   ├── m11_navigation.feature            # BDD contract (this milestone)
│   │   └── m11_navigation_widget_test.dart   # step 4
│   ├── theme/
│   │   └── app_theme_test.dart               # step 1
│   └── ui/
│       └── neumorphic_container_test.dart    # step 2
│       └── bottom_nav_bar_test.dart          # step 3
├── lib/core/theme/
│   └── app_theme.dart                        # Montserrat font (modified)
├── lib/ui/
│   ├── atoms/
│   │   └── neumorphic_container.dart         # new reusable widget
│   ├── organisms/
│   │   └── bottom_nav_bar.dart               # 4 tabs + neumorphic (modified)
│   └── pages/
│       ├── main_shell_page.dart              # new tab shell
│       ├── routines_page.dart                # new mock screen
│       ├── nutrition_page.dart               # new mock screen
│       ├── schedule_page.dart                # new mock screen
│       └── profile_page.dart                 # new mock screen
└── docs/
    └── m11_execution_changes.log             # Coder log
```

---

## 7. Definition of Done (DoD)

- Every scenario in `test/features/m11_navigation.feature` has a passing test.
- `flutter test` green (full suite, no regressions).
- `flutter analyze` reports no issues introduced by this milestone.
- The app shell shows exactly the 4 tabs: ROUTINES, NUTRITION, SCHEDULE,
  PROFILE.
- Each tab renders its mock content (routines list, nutrition plan, calendar,
  profile).
- Global font family is Montserrat; bottom nav and cards use the neumorphic
  container (soft light/dark shadows).
- `docs/m11_execution_changes.log` written and committed.

---

## 8. Open decisions (non-blocking)

1. Whether the tab shell replaces `HomePage` entirely or wraps it; recommend
   a new `MainShellPage` that owns tab state and delegates each tab body to
   its mock screen (the old dashboard can be dropped or moved to a later
   milestone).
2. Whether to fully replace Material `NavigationBar` with a hand-built
   neumorphic tab bar, or wrap the existing `NavigationBar` in a
   `NeumorphicContainer`. Recommend wrapping for accessibility (labels/icons
   retained) — Coder decides the cleanest approach to satisfy the shadow test.
3. `google_fonts` runtime font fetching vs. bundled assets: for deterministic
   tests, prefer the package's cached/bundled resolution and a fallback family.
