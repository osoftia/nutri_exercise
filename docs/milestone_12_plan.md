# Milestone 12 — User Profile Management Plan

> **Author:** @Architect
> **Status:** Ready for @Coder implementation (strict TDD)
> **Branch:** `feature/m12-profile-management`
> **Contract:** `mobile_app/test/features/m12_profile.feature`

---

## 1. Scope

Give life to the **PROFILE** tab (index 3 of the M11 `MainShellPage`) by
replacing the static mock profile with an editable, locally-persisted user
profile:

1. A **neumorphic form** to view and edit **Name, Age, Weight, Height** and
   **Fitness Goal**.
2. A **local repository** (SQLite via the existing `DatabaseHelper`) to
   persist the profile data.
3. **State management** so saved changes are reflected immediately on the
   Profile UI.

No networking is involved — this milestone is fully local.

---

## 2. Current state analysis

- `lib/ui/pages/profile_page.dart` is a **StatelessWidget** rendering hardcoded
  mock stats (`Alex Carter` / `Muscle Gain` / static rows) — no persistence.
- `lib/ui/pages/main_shell_page.dart` builds `const [RoutinesPage(),
  NutritionPage(), SchedulePage(), ProfilePage()]`.
- The app already has a proven local-persistence pattern:
  - `DatabaseHelper` (`lib/core/database/database_helper.dart`) — SQLite with
    an **in-memory override** for tests; tables `routines`, `diets`,
    `notification_prefs`.
  - Abstract repositories in `lib/core/data/`, SQLite implementations
    `Local*Repository`, and in-memory `Mock*Repository` in `lib/core/mocks/`.
  - Constructor-based DI (see `SettingsPage`).
- State management: the codebase currently uses `StatefulWidget` +
  `FutureBuilder`/local state. M12 introduces a small **ChangeNotifier**
  controller (no external package required; rebuilt with Flutter's built-in
  `ListenableBuilder`).

### Gaps to fill (Green phase)
- A `UserProfile` model (name, age, weight, height, fitnessGoal).
- A `profile` SQLite table (single row, `id = 1`) + `DatabaseHelper` accessors.
- `ProfileRepository` (abstract), `LocalProfileRepository`, `MockProfileRepository`.
- `UserProfileController extends ChangeNotifier` for load/save + notify.
- Rewrite `ProfilePage` as a neumorphic, repository-backed edit form.

---

## 3. New components

### 3.1 Model — `lib/core/models/user_profile.dart`

```dart
enum FitnessGoal { muscleGain, fatLoss, maintain, endurance }

class UserProfile {
  const UserProfile({
    required this.name,
    required this.age,
    required this.weightKg,
    required this.heightCm,
    required this.goal,
  });

  final String name;
  final int age;
  final double weightKg;
  final double heightCm;
  final FitnessGoal goal;

  Map<String, Object?> toMap();          // for SQLite row
  static UserProfile fromMap(...);        // from SQLite row
  static const UserProfile empty;         // blank defaults for a fresh form
}
```

### 3.2 Persistence

**`DatabaseHelper`** — add table + accessors:

```sql
CREATE TABLE profile (
  id INTEGER PRIMARY KEY CHECK (id = 1),   -- single-row table
  name TEXT NOT NULL,
  age INTEGER NOT NULL,
  weight_kg REAL NOT NULL,
  height_cm REAL NOT NULL,
  goal TEXT NOT NULL
)
```

- `Future<Map<String, Object?>?> getProfile()`
- `Future<void> upsertProfile(UserProfile profile)`

**`ProfileRepository`** (abstract, `lib/core/data/profile_repository.dart`):

```dart
abstract interface class ProfileRepository {
  Future<UserProfile?> getProfile();               // null when never saved
  Future<void> saveProfile(UserProfile profile);   // upsert single row
}
```

**`LocalProfileRepository`** (`lib/core/data/local_profile_repository.dart`)
mirrors `LocalSettingsRepository` (injectable `DatabaseHelper`).

**`MockProfileRepository`** (`lib/core/mocks/mock_profile_repository.dart`)
in-memory map; optional seed; `null` by default.

### 3.3 State management — `lib/core/state/user_profile_controller.dart`

```dart
class UserProfileController extends ChangeNotifier {
  UserProfileController({required ProfileRepository repository});
  UserProfile? profile;                  // null while loading / never saved
  bool isLoading;
  Future<void> load();                   // read + notifyListeners()
  Future<void> save(UserProfile p);      // persist + set + notifyListeners()
}
```

Consumers rebuild via `ListenableBuilder(listenable: controller, ...)`. This
satisfies "state management to immediately reflect saved changes".

### 3.4 UI — rewrite `lib/ui/pages/profile_page.dart`

`ProfilePage` becomes a `StatefulWidget` with constructor DI:

```dart
ProfilePage({required UserProfileController controller});
```

Layout (keeping the M11 neumorphic aesthetic — `NeumorphicContainer` +
`AppColors`/`AppTheme` tokens):

- Header `AppHeading('Profile')` + neumorphic avatar (initials derived from
  the name, e.g. `JD`).
- A **`Form`** inside a `NeumorphicContainer` with 5 fields:
  - Name (`TextFormField`, required, key `profile_name_field`)
  - Age (`TextFormField`, numeric, key `profile_age_field`)
  - Weight (`TextFormField`, numeric, key `profile_weight_field`)
  - Height (`TextFormField`, numeric, key `profile_height_field`)
  - Fitness Goal (dropdown `FitnessGoal`, key `profile_goal_field`)
- A neumorphic **Save** button (key `profile_save_button`) that:
  1. validates the form,
  2. builds a `UserProfile`,
  3. calls `controller.save(...)` → `notifyListeners()` → form + avatar refresh
     immediately.
- Validation: Name required; Age/Weight/Height numeric and ≥ 1.
- `initState` triggers `controller.load()` (guard against double-load).

### 3.5 Wiring

- `lib/app.dart`: build a `ProfileRepository` from `config` (`useMocks` →
  `MockProfileRepository`, else `LocalProfileRepository`), create one
  `UserProfileController`, and pass it into `MainShellPage`.
- `lib/ui/pages/main_shell_page.dart`: accept a required
  `UserProfileController`, build the tab list with
  `ProfilePage(controller: ...)` (no longer a `const` list).

---

## 4. Mocking strategy for tests

- **`MockProfileRepository`** seeds/returns an in-memory `UserProfile`; used by
  widget tests and the controller tests so no SQLite is touched.
- **`DatabaseHelper`** unit tests use the **in-memory override** to verify
  real SQLite round-trip persistence (`getProfile` → `saveProfile` →
  `getProfile`).
- **Controller tests** assert `load`/`save` populate state and fire
  `notifyListeners` (via `addListener` counter).
- **Existing M11 shell test** (`m11_navigation_widget_test.dart`) is updated:
  the Profile tab now asserts the form (e.g. `profile_name_field` exists) and
  `MainShellPage` is pumped with a `MockProfileRepository`-backed controller.
  `widget_test.dart`'s `NutriApp` dev test keeps working via `useMocks`.

---

## 5. TDD Execution Order (for @Coder)

Follow Red → Green strictly. Run `flutter test` (target file) after each step;
`flutter analyze` at the end of Green.

| Step | Test (RED) | Implementation (GREEN) |
|------|-----------|------------------------|
| 0 | (contract) keep `test/features/m12_profile.feature` as source of truth | — |
| 1 | **Model test** `test/models/user_profile_test.dart`: construct + `toMap`/`fromMap` round-trip; `UserProfile.empty`. (RED: class missing) | Create `FitnessGoal` + `UserProfile`. |
| 2 | **Repo contract test** `test/data/profile_repository_test.dart`: `MockProfileRepository` returns `null` initially, returns saved profile after `saveProfile`. (RED) | Create abstract `ProfileRepository` + `MockProfileRepository`. |
| 3 | **Local persistence test** `test/data/local_profile_repository_test.dart`: in-memory `DatabaseHelper`; `null` default, save→get round-trip, upsert overwrites. (RED: no table/methods) | Add `profile` table + `getProfile`/`upsertProfile` to `DatabaseHelper`; create `LocalProfileRepository`. |
| 4 | **Controller test** `test/state/user_profile_controller_test.dart`: `load` populates + notifies; `save` persists + notifies. (RED) | Create `UserProfileController` (ChangeNotifier). |
| 5 | **Profile page widget test** `test/features/m12_profile_widget_test.dart`: shows saved details; edit+save reflects immediately (and persists via mock repo); empty-name validation blocks save; form inside `NeumorphicContainer`. (RED: page not form-backed) | Rewrite `ProfilePage` as form + wire controller. |
| 6 | **Shell wiring**: update `main_shell_page.dart` + `app.dart`; update `m11_navigation_widget_test.dart` Profile scenario + verify `widget_test.dart`. (RED until wired) | Wire controller through `MainShellPage`/`NutriApp`. |
| 7 | **Regression + log + commit**: full `flutter test`, `flutter analyze`, `docs/m12_execution_changes.log`, `git add .` + commit. | — |

---

## 6. Files created / modified (proposal)

```
mobile_app/
├── test/
│   ├── features/
│   │   ├── m12_profile.feature                   # BDD contract (this milestone)
│   │   ├── m12_profile_widget_test.dart          # step 5
│   │   └── m11_navigation_widget_test.dart       # step 6 (modified)
│   ├── models/
│   │   └── user_profile_test.dart                # step 1
│   ├── data/
│   │   ├── profile_repository_test.dart          # step 2
│   │   └── local_profile_repository_test.dart    # step 3
│   └── state/
│       └── user_profile_controller_test.dart     # step 4
├── lib/core/
│   ├── models/
│   │   └── user_profile.dart                     # new model + enum
│   ├── data/
│   │   ├── profile_repository.dart               # abstract
│   │   └── local_profile_repository.dart         # SQLite-backed
│   ├── mocks/
│   │   └── mock_profile_repository.dart
│   ├── state/
│   │   └── user_profile_controller.dart          # ChangeNotifier
│   └── database/
│       └── database_helper.dart                  # + profile table/methods (modified)
├── lib/ui/pages/
│   ├── profile_page.dart                         # rewritten as form (modified)
│   └── main_shell_page.dart                      # DI controller (modified)
├── lib/app.dart                                  # wire repository + controller (modified)
└── docs/
    └── m12_execution_changes.log                 # Coder log
```

---

## 7. Definition of Done (DoD)

- Every scenario in `test/features/m12_profile.feature` has a passing test.
- `flutter test` green (full suite, no regressions).
- `flutter analyze` reports no issues introduced by this milestone.
- Profile edit/delete is persisted via SQLite (verified with in-memory DB).
- Saving changes updates the Profile UI immediately (ChangeNotifier).
- Name validation blocks empty saves; numeric fields accept numbers only.
- Profile form is rendered with the neumorphic container aesthetic.
- `docs/m12_execution_changes.log` written and committed.

---

## 8. Open decisions (non-blocking)

1. **Fitness Goal values** — fixed enum (muscleGain, fatLoss, maintain,
   endurance) vs. free text. Recommend the enum for a clean dropdown; free
   text can be a follow-up.
2. **Units** — Weight assumed kg, Height cm for the numeric fields (labels
   shown in the form). Unit toggles are out of scope.
3. **State management scope** — a single `UserProfileController` scoped to the
   Profile tab for now; lifting it to an app-wide scope (e.g. for stats on
   other tabs) can be a follow-up.
4. **`MainShellPage` DI shape** — pass the controller (recommended) rather than
   the repository, so the shell never touches persistence directly.