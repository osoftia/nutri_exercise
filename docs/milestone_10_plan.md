# Milestone 10 — Settings & Notifications Module Plan

> **Author:** @Architect
> **Status:** Ready for @Coder implementation (strict TDD)
> **Branch:** `feature/m10-settings-notifications`
> **Contract:** `mobile_app/test/features/m10_settings.feature`

---

## 1. Scope

Add a **Settings screen** for the Flutter `mobile_app` that lets the user:

1. **View, edit, and delete saved database records** (routines/exercises).
2. Manage **notification preferences** via toggles:
   - Exercise alerts
   - Food alerts
   - Daily intake reminders

This milestone introduces the first `Settings` page (navigation index 4 of the
existing `BottomNavBar`, which already declares 5 tabs) and the data-access and
preference-persistence plumbing to support it.

---

## 2. Data layer analysis (current state)

- `DatabaseHelper` (`lib/core/database/database_helper.dart`) owns SQLite:
  - tables `routines(id, weekday, focus, exercises_json)` and
    `diets(id, date, total_calories, meals_json)`
  - exposes `getRoutines()`, `getDiets()`, `upsertRoutine()`, `upsertDiet()`
  - supports an in-memory `Database?` override for tests.
- `LocalRoutineRepository` / `LocalDietRepository` implement get + upsert but
  **no delete** and **no single-record get/edit by id**.
- `NotificationService` (`lib/core/services/notification_service.dart`) wraps
  `flutter_local_notifications` and schedules weekly routine reminders. It has
  **no preference model** and no per-type toggle gating.

### Gaps to fill (Green phase)
- Add `deleteRoutine(int id)` (and optionally `deleteDiet(int id)`) to
  `DatabaseHelper` + `LocalRoutineRepository`.
- Add a `SettingsRepository`-style abstraction for **notification preferences**
  persisted to a dedicated SQLite table (`notification_prefs`), keyed by
  pref id, so toggles survive restarts.
- Add a `SettingsPage` UI screen with two sections: **Saved Records** and
  **Notification Preferences**.

---

## 3. New components

### 3.1 Persistence

**`DatabaseHelper`** — add table + CRUD:

```sql
CREATE TABLE notification_prefs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  pref_key TEXT NOT NULL UNIQUE,   -- e.g. 'exercise_alerts'
  enabled INTEGER NOT NULL         -- 0/1
)
```

New methods:
- `Future<List<Map<String, Object?>>> getNotificationPrefs()`
- `Future<void> upsertNotificationPref(String key, bool enabled)`
- `Future<void> deleteRoutine(int id)` (and `deleteDiet(int id)` for parity)

**`NotificationPrefsRepository`** (abstract) + **`LocalNotificationPrefsRepository`**
in `lib/core/data/` — mirroring the existing repository pattern:
- `Future<bool> isEnabled(NotificationPrefType type)`
- `Future<void> setEnabled(NotificationPrefType type, bool value)`
- Defaults to **all disabled** when no row exists.

**`NotificationPrefType`** enum in `lib/core/models/`:
`exerciseAlerts`, `foodAlerts`, `dailyIntakeReminders` (maps to pref keys).

### 3.2 UI

**`SettingsPage`** (`lib/ui/pages/settings_page.dart`), a `StatefulWidget` with
constructor-based DI:
- `final RoutineRepository routineRepository;` (for records CRUD)
- `final NotificationPrefsRepository prefsRepository;` (for toggles)

Layout (two `ListTile`-section groups, matching the app's dark theme tokens):

1. **Saved Records**
   - Lists each `WorkoutDay` (weekday + focus).
   - Tap a record → expand/inspect (exercises, sets, reps) — reuse
     `routine_models` `Exercise` fields.
   - Edit action → edit the `focus` (and optionally exercise fields) in a
     dialog, save via `LocalRoutineRepository.saveRoutine`.
   - Delete action → confirm then `LocalRoutineRepository.deleteRoutine(id)`,
     refresh the list.

2. **Notification Preferences**
   - `SwitchListTile` for each `NotificationPrefType`:
     - "Exercise alerts"
     - "Food alerts"
     - "Daily intake reminders"
   - On toggle, persist via `NotificationPrefsRepository.setEnabled(...)`.

### 3.3 Integration

- Wire `SettingsPage` into navigation. The existing `BottomNavBar`
  (`lib/ui/organisms/bottom_nav_bar.dart`) declares 5 tabs; index 4 is the
  settings/profile tab. In `HomePage` (or a shell), selecting the Settings tab
  shows `SettingsPage`. Exact wiring is decided by @Coder; at minimum the page
  must be reachable and constructible with real repositories.

---

## 4. Mocking strategy for tests

Mirror the established constructor-DI pattern used across the app.

- **`MockRoutineRepository`** already exists; it can be used to seed the list
  of routines for the Saved Records section. Add an in-memory delete/update
  behavior if needed for the edit/delete scenarios (see §5).
- **`NotificationPrefsRepository`** — provide **`MockNotificationPrefsRepository`**
  (in-memory map) so widget tests toggle switches without touching SQLite.
- **`DatabaseHelper`** unit tests use the **in-memory database override**
  (`sqflite_common_ffi` in-memory or the existing override hook) to verify
  real CRUD persistence.

---

## 5. TDD Execution Order (for @Coder)

Follow Red → Green strictly. Run `flutter test` (target file) after each step;
`flutter analyze` at the end of Green.

| Step | Test (RED) | Implementation (GREEN) |
|------|-----------|------------------------|
| 0 | (contract) keep `test/features/m10_settings.feature` as source of truth | — |
| 1 | **Prefs repo contract test** `test/data/notification_prefs_repository_test.dart`: `MockNotificationPrefsRepository` defaults all `false`, `setEnabled` persists in memory. (RED: classes missing) | Create `NotificationPrefType` model, abstract `NotificationPrefsRepository`, `MockNotificationPrefsRepository`. |
| 2 | **Local prefs persistence test**: use in-memory `DatabaseHelper`; verify `setEnabled` then `isEnabled` round-trips and defaults to `false`. (RED: no table/methods) | Add `notification_prefs` table + `getNotificationPrefs`/`upsertNotificationPref` to `DatabaseHelper`; add `LocalNotificationPrefsRepository`. |
| 3 | **Routine delete persistence test**: in-memory DB, insert a routine, `deleteRoutine(id)`, assert gone. (RED: no delete) | Add `deleteRoutine` (+ `deleteDiet`) to `DatabaseHelper` and `LocalRoutineRepository`. |
| 4 | **Settings page widget test — records list** `test/features/m10_settings_widget_test.dart`: pump `SettingsPage` with `MockRoutineRepository`; expect weekday records + focus shown. (RED: page missing) | Create `SettingsPage` rendering the Saved Records list. |
| 5 | **View scenario**: tap a record → details (exercises, sets, reps) shown. (RED) | Add expand/detail behavior. |
| 6 | **Edit scenario**: edit focus, save → list + DB updated. (RED) | Add edit dialog + `saveRoutine` call + refresh. |
| 7 | **Delete scenario**: delete a record → removed from list + DB. (RED) | Add confirm + `deleteRoutine` + refresh. |
| 8 | **Notification toggles widget test**: `SettingsPage` with `MockNotificationPrefsRepository`; toggles switch UI + persist; re-open shows persisted state. (RED) | Add Notification Preferences section with `SwitchListTile`s wired to prefs repo. |
| 9 | **Integration**: wire `SettingsPage` into nav so it is reachable from the shell. | Edit navigation wiring. |
| 10 | **Regression + log + commit**: full `flutter test`, `flutter analyze`, `docs/m10_execution_changes.log`, `git add .` + commit. | — |

---

## 6. Files created / modified (proposal)

```
mobile_app/
├── test/
│   ├── features/
│   │   └── m10_settings.feature                 # BDD contract (this milestone)
│   ├── data/
│   │   └── notification_prefs_repository_test.dart   # step 1-2
│   ├── data/
│   │   └── routine_delete_test.dart                 # step 3
│   └── features/
│       └── m10_settings_widget_test.dart            # steps 4-8
├── lib/core/
│   ├── models/
│   │   └── notification_pref.dart               # NotificationPrefType enum
│   ├── data/
│   │   ├── notification_prefs_repository.dart   # abstract
│   │   └── local_notification_prefs_repository.dart
│   ├── mocks/
│   │   └── mock_notification_prefs_repository.dart
│   ├── database/
│   │   └── database_helper.dart                 # + prefs table, deletes (modified)
│   └── data/
│       └── local_routine_repository.dart        # + deleteRoutine (modified)
├── lib/ui/
│   └── pages/
│       └── settings_page.dart                   # new Settings screen
└── docs/
    └── m10_execution_changes.log                # Coder log
```

---

## 7. Definition of Done (DoD)

- Every scenario in `test/features/m10_settings.feature` has a passing test.
- `flutter test` green (full suite, no regressions).
- `flutter analyze` reports no issues introduced by this milestone.
- Record edit/delete actually persists via SQLite (verified with in-memory DB).
- Notification prefs persist across screen changes.
- `docs/m10_execution_changes.log` written and committed.

---

## 8. Open decisions (non-blocking)

1. Whether the Settings screen is a dedicated route or a tab body within the
   existing 5-tab shell (Coder decides; tab index 4 is the natural slot).
2. Scope of "edit": focus-only vs. full exercise editing. Recommend focus-only
   for this milestone; full exercise editing can be a follow-up.
3. Whether toggles also gate actual `NotificationService.schedule...` calls
   now or just persist state (recommend persist state now; gate scheduling in
   a follow-up to avoid reworking the existing weekly-reminder flow).