# Milestone 13 — Schedule & Calendar View Plan

> **Author:** @Architect
> **Status:** Ready for @Coder implementation (strict TDD)
> **Branch:** `feature/m13-schedule-calendar`
> **Contract:** `mobile_app/test/features/m13_schedule.feature`

---

## 1. Scope

Give life to the **SCHEDULE** tab (index 2 of the M11 `MainShellPage`) by
replacing the static August 2026 calendar with an **interactive neumorphic
calendar** plus a **daily agenda**:

1. A **neumorphic calendar view** (custom interactive widget, no external
   package — keeps the app dependency-light and the M11 neumorphic aesthetic).
2. A **daily agenda** below the calendar listing mock scheduled events for the
   **selected date** (e.g. "Leg Day Workout", "High Protein Breakfast").
3. **State management** for date selection that updates the agenda dynamically
   (mirrors the M12 `UserProfileController` `ChangeNotifier` pattern).

No persistence or networking is required — the events are seeded mock data.

---

## 2. Current state analysis

- `lib/ui/pages/schedule_page.dart` is a **StatelessWidget** rendering a fixed
  August 2026 grid: a `NeumorphicContainer` (`calendar_grid` key) with a month
  label, Mo–Su header row, and a `Wrap` of 40×40 day tiles. Workout days are
  hardcoded `{5, 12, 19, 26}` and highlighted with a primary-tinted fill.
  There is **no tap handling**, **no month navigation**, and **no agenda**.
- The app already has a proven state-management pattern from M12:
  `UserProfileController extends ChangeNotifier` (in `lib/core/state/`)
  consumed via Flutter's built-in `ListenableBuilder`, repositories in
  `lib/core/data/` + `lib/core/mocks/`, and constructor-based DI through
  `MainShellPage`/`app.dart`.

### Gaps to fill (Green phase)
- A `ScheduleEvent` model (title, category, time label) keyed by date.
- A `ScheduleRepository` (abstract) + `MockScheduleRepository` seeded with
  events across several days of a **fixed reference month** (August 2026) so
  tests are deterministic.
- A `ScheduleController extends ChangeNotifier` exposing:
  `visibleMonth`, `selectedDate`, `eventsByDate`, `eventsForSelectedDate`,
  `selectDate(...)`, `nextMonth()`, `previousMonth()`.
- Rewrite `SchedulePage` as a `StatefulWidget` with a tappable neumorphic
  calendar (day markers for days with events, selected-day highlight) and a
  neumorphic daily agenda below.

---

## 3. New components

### 3.1 Model — `lib/core/models/schedule_event.dart`

```dart
enum ScheduleEventType { workout, meal, rest }

class ScheduleEvent {
  const ScheduleEvent({
    required this.date,      // DateTime (day precision)
    required this.title,
    required this.time,      // display label, e.g. '07:00'
    required this.type,
  });
}
```

### 3.2 Repository — `lib/core/data/schedule_repository.dart`

```dart
abstract interface class ScheduleRepository {
  /// All events across the seeded range (mock for M13).
  Future<List<ScheduleEvent>> getEvents();
}
```

**`MockScheduleRepository`** (`lib/core/mocks/mock_schedule_repository.dart`)
returns a hardcoded list seeded on fixed dates, e.g. August 2026:
- Aug 5: "Leg Day Workout" (workout), "High Protein Breakfast" (meal).
- Aug 12: "Pull Day Workout" (workout), "Grilled Salmon Lunch" (meal).
- Aug 19: "Push Day Workout" (workout).
- Aug 26: "Leg Day Workout" (workout), "Post-workout Shake" (meal).
- Other dates: no events (for the empty-agenda scenario).

> A `LocalScheduleRepository` (SQLite) is intentionally **out of scope** —
> M13 is mock-data only; persistence can be a follow-up.

### 3.3 State management — `lib/core/state/schedule_controller.dart`

```dart
class ScheduleController extends ChangeNotifier {
  ScheduleController({
    required ScheduleRepository repository,
    DateTime? initialMonth,   // default DateTime.now() month; inject for tests
  });

  DateTime visibleMonth;               // first day of the displayed month
  DateTime selectedDate;
  List<ScheduleEvent> eventsForSelectedDate;  // derived from events + date
  bool isLoading;

  Future<void> load();                  // read events + notify
  void selectDate(DateTime date);       // set + recompute agenda + notify
  void nextMonth();                     // visibleMonth += 1 month + notify
  void previousMonth();                 // visibleMonth -= 1 month + notify
}
```

`eventsForSelectedDate` filters `eventsByDate[selectedDate]`; the agenda
rebuilds automatically via `ListenableBuilder`.

### 3.4 UI — rewrite `lib/ui/pages/schedule_page.dart`

`SchedulePage` becomes a `StatefulWidget` with constructor DI:

```dart
SchedulePage({required ScheduleController controller});
```

Layout (keeping the neumorphic aesthetic):

1. **Calendar** (`NeumorphicContainer`, key `calendar_grid`):
   - Month header row: previous-month control (key `prev_month_button`),
     `AppText('August 2026')` month label, next-month control
     (key `next_month_button`).
   - Mo–Su weekday header row.
   - A `Wrap`/`GridView` of day tiles. Each tile (key `day_<d>`):
     - **tappable** → `controller.selectDate(date)`;
     - **selected** → primary fill + accent border;
     - **has events** → a small marker dot (key `day_marker_<d>`).
2. **Daily agenda** (`NeumorphicContainer`, key `daily_agenda`):
   - Heading for the selected date (`AppHeading`).
   - Each event as a neumorphic row: title + time label + type icon.
   - Empty state: `AppText('No events scheduled')`.

### 3.5 Wiring

- `lib/ui/pages/main_shell_page.dart`: accept a required
  `ScheduleController` and pass it to `SchedulePage` (mirrors M12
  `ProfileController` wiring; tab list stays built in `State`).
- `lib/app.dart`: build `ScheduleRepository` (`useMocks` → mock; else mock for
  now since no local impl exists) + `ScheduleController`, inject into
  `MainShellPage`.

---

## 4. Mocking strategy for tests

- **`MockScheduleRepository`** seeds fixed August 2026 events — no SQLite
  needed for widget tests.
- **Controller tests** assert `load`, `selectDate` (agenda recompute + notify),
  and month navigation (`nextMonth`/`previousMonth`).
- **Widget tests** pump `SchedulePage` with a controller whose `initialMonth`
  is pinned to `DateTime(2026, 8)` so `find.text('August 2026')` etc. are
  deterministic.
- **Existing M11 shell test** (`m11_navigation_widget_test.dart`) is updated
  like M12 did for Profile: pump `MainShellPage` with a mock-backed
  `ScheduleController`; the Schedule-tab scenario asserts the calendar + agenda
  (e.g. `daily_agenda` key) instead of only `calendar_grid`.

---

## 5. TDD Execution Order (for @Coder)

Follow Red → Green strictly. Run `flutter test` (target file) after each step;
`flutter analyze` at the end of Green.

| Step | Test (RED) | Implementation (GREEN) |
|------|-----------|------------------------|
| 0 | (contract) keep `test/features/m13_schedule.feature` as source of truth | — |
| 1 | **Model test** `test/models/schedule_event_test.dart`: construct + fields + type. (RED: class missing) | Create `ScheduleEventType` + `ScheduleEvent`. |
| 2 | **Repo test** `test/data/schedule_repository_test.dart`: `MockScheduleRepository` returns seeded events; events exist on 5/12/19/26 and none on 3. (RED) | Create `ScheduleRepository` + `MockScheduleRepository`. |
| 3 | **Controller test** `test/state/schedule_controller_test.dart`: `load` populates agenda; `selectDate(5)` → agenda has "Leg Day Workout"; `selectDate(3)` → empty; `nextMonth`/`previousMonth` shift the label; notifies on each. (RED) | Create `ScheduleController`. |
| 4 | **Schedule page widget test** `test/features/m13_schedule_widget_test.dart`: month label + weekday header + day tiles; tap day 5 → agenda shows events; tap day 3 → empty message; tap day 12 → agenda swaps; day markers present; prev/next month updates label; calendar + agenda inside `NeumorphicContainer`. (RED: page not interactive) | Rewrite `SchedulePage` as interactive calendar + agenda. |
| 5 | **Shell wiring**: update `main_shell_page.dart` + `app.dart`; update `m11_navigation_widget_test.dart` Schedule scenario + verify `widget_test.dart`. (RED until wired) | Wire `ScheduleController` through `MainShellPage`/`NutriApp`. |
| 6 | **Regression + log + commit**: full `flutter test`, `flutter analyze`, `docs/m13_execution_changes.log`, `git add .` + commit. | — |

---

## 6. Files created / modified (proposal)

```
mobile_app/
├── test/
│   ├── features/
│   │   ├── m13_schedule.feature               # BDD contract (this milestone)
│   │   ├── m13_schedule_widget_test.dart      # step 4
│   │   └── m11_navigation_widget_test.dart    # step 5 (modified)
│   ├── models/
│   │   └── schedule_event_test.dart           # step 1
│   ├── data/
│   │   └── schedule_repository_test.dart      # step 2
│   └── state/
│       └── schedule_controller_test.dart      # step 3
├── lib/core/
│   ├── models/
│   │   └── schedule_event.dart                # new model + enum
│   ├── data/
│   │   └── schedule_repository.dart           # abstract
│   ├── mocks/
│   │   └── mock_schedule_repository.dart
│   └── state/
│       └── schedule_controller.dart           # ChangeNotifier
├── lib/ui/pages/
│   ├── schedule_page.dart                     # rewritten interactive (modified)
│   └── main_shell_page.dart                   # DI controller (modified)
├── lib/app.dart                               # wire controller (modified)
└── docs/
    └── m13_execution_changes.log              # Coder log
```

---

## 7. Definition of Done (DoD)

- Every scenario in `test/features/m13_schedule.feature` has a passing test.
- `flutter test` green (full suite, no regressions).
- `flutter analyze` reports no issues introduced by this milestone.
- Tapping a calendar day updates the agenda dynamically (ChangeNotifier).
- Days with events show a marker; the selected day is visually highlighted.
- Month navigation (prev/next) updates the displayed month label + grid.
- Calendar and daily agenda are rendered inside `NeumorphicContainer`.
- `docs/m13_execution_changes.log` written and committed.

---

## 8. Open decisions (non-blocking)

1. **Custom calendar vs `table_calendar`** — recommend a custom interactive
   grid to keep the neumorphic look and zero new dependencies; `table_calendar`
   (wrapped in `NeumorphicContainer`) is the alternative if rich built-in
   gestures are wanted later.
2. **Reference month** — the mock events live on fixed August 2026 dates;
   `ScheduleController.initialMonth` defaults to `DateTime.now()` in the app
   but is injectable so tests pin `DateTime(2026, 8)`. If "today" should drive
   events, seed relative dates — not recommended for M13 determinism.
3. **Event shape** — title + time label + type only; start/end times, colors,
   or recurrence are follow-ups.
4. **Persistence** — mock-only for M13; a `LocalScheduleRepository` on the
   `schedule_events` SQLite table can be a follow-up milestone.