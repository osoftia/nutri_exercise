# NutriExercise Mobile App — Architecture

This document describes the technical architecture of `mobile_app`, a Flutter
application that provides a fitness/nutrition dashboard with an interactive
muscle map, weekly workout routines, daily meal plans, offline persistence, and
local reminders.

The app follows a simple layered architecture that separates **core logic**
(models, data access, services, configuration, theme) from the **UI layer**
(organized using atomic design: atoms → molecules → organisms → pages).

---

## Directory Tree

```
mobile_app/
├── lib/
│   ├── main.dart                    # Entry point: dev config (mocks)
│   ├── main_dev.dart                # Entry point: dev config (mocks)
│   ├── main_local.dart              # Entry point: Offline-First SQLite mode
│   ├── main_qa.dart                 # Entry point: QA API mode
│   ├── main_prod.dart               # Entry point: Production API mode
│   ├── app.dart                     # NutriApp root widget: DI + MaterialApp
│   │
│   ├── core/                        # Domain, data, services and configuration
│   │   ├── config/
│   │   │   └── app_config.dart      # AppConfig: env name, mocks/API/local flags
│   │   ├── data/                    # Repository contracts + implementations
│   │   │   ├── diet_repository.dart      # DietRepository (abstract)
│   │   │   ├── routine_repository.dart   # RoutineRepository (abstract)
│   │   │   ├── http_diet_repository.dart # REST implementation
│   │   │   ├── http_routine_repository.dart
│   │   │   ├── local_diet_repository.dart# SQLite implementation
│   │   │   └── local_routine_repository.dart
│   │   ├── database/
│   │   │   └── database_helper.dart # SQLite helper (sqflite, 2 tables)
│   │   ├── mocks/
│   │   │   ├── mock_diet_repository.dart    # Sample data + mock repository
│   │   │   └── mock_routine_repository.dart
│   │   ├── models/
│   │   │   ├── diet_models.dart     # MealType, Meal, DailyMenu
│   │   │   └── routine_models.dart  # Exercise, WorkoutDay
│   │   ├── services/
│   │   │   ├── ai_interceptor.dart      # AiService + OfflineException (connectivity guard)
│   │   │   └── notification_service.dart# Local notifications (weekly reminders)
│   │   └── theme/
│   │       └── app_theme.dart       # AppColors, AppSpacing, AppRadius, AppTheme
│   │
│   └── ui/                          # Presentation layer (atomic design)
│       ├── atoms/                   # Smallest reusable widgets
│       │   ├── custom_button.dart   # CustomButton (primary / ghost / text)
│       │   ├── neumorphic_fab.dart  # NeumorphicFab (circular AI FAB)
│       │   └── typography.dart      # AppHeading, AppText, AppCaption
│       ├── molecules/               # Composed UI blocks
│       │   ├── offline_ai_dialog.dart # OfflineAiDialog + helper
│       │   ├── ai_chat_sheet.dart     # AiChatSheet (AI assistant chat)
│       │   └── wizard_voice_input_field.dart
│       ├── organisms/               # Complex, feature-specific widgets
│       │   └── bottom_nav_bar.dart      # Material 3 NavigationBar
│       └── pages/
│           ├── main_shell_page.dart     # Tabbed shell + AI FAB host
│           ├── routines_page.dart
│           ├── nutrition_page.dart
│           ├── schedule_page.dart
│           └── profile_page.dart
│
├── test/                           # Unit + widget tests (see Tests section)
│   ├── ui/
│   ├── features/
│   ├── data/
│   ├── state/
│   ├── models/
│   └── services/
│
├── android/                        # Android host project (plugin receivers declared)
├── ios/                            # iOS host project
├── pubspec.yaml                    # Project manifest and dependencies
└── pubspec.lock                    # Resolved dependency graph
```

---

## Architecture Overview

### State Management

The app intentionally uses **no third-party state-management library**.
State is handled with:

- **`StatefulWidget` + `setState`** for local UI state (e.g. `AiChatSheet`,
  `MainShellPage`).
- **`ChangeNotifier` controllers** (`UserProfileController`,
  `ScheduleController`, `NutritionController`, `ProjectionController`) consumed
  through `ListenableBuilder` for cross-page state.
- **`FutureBuilder` chaining** for asynchronous data loading (routines and
  menus are held as `Future`s and resolved in the build tree).
- **Constructor-based dependency injection**: repository implementations are
  chosen in the root widget (`NutriApp`) based on `AppConfig` and passed down
  to the UI. This keeps the presentation layer decoupled from data sources.

### Offline-First SQLite

- Persistence uses **`sqflite`** with **`path_provider`**.
- `DatabaseHelper` (in `core/database/database_helper.dart`) manages a single
  database file (`nutri_exercise.db`, version 1) stored in the app documents
  directory, with `PRAGMA foreign_keys = ON`.
- Two tables store the domain models; nested collections are serialized as
  JSON columns:

  ```
  routines(id, weekday, focus, exercises_json)
  diets(id, date, total_calories, meals_json)
  ```

- `LocalRoutineRepository` and `LocalDietRepository` implement the same
  interfaces as the HTTP repositories. On first access they **seed** the
  database from the built-in mock data, then serve reads from SQLite and
  expose write paths (`saveRoutine`, `saveDiet`). The "local" flavor is
  selected through `main_local.dart`.

### AI Network Interceptor

- `core/services/ai_interceptor.dart` provides the **`AiService`** guard
  together with `OfflineException`.
- It uses **`connectivity_plus`** to detect the current connectivity state and
  exposes `ensureOnline()`, which throws `OfflineException` when the device has
  no active connection.
- In the UI, the **AI assistant chat** (`AiChatSheet`) calls this guard before
  every request: offline sends open the `OfflineAiDialog`, while online sends
  call `RoutineRepository.generateRoutine()` and render the result as an inline
  assistant bubble. The chat is opened from a `NeumorphicFab` on
  `MainShellPage`.

### Local Notifications

- `core/services/notification_service.dart` wraps
  **`flutter_local_notifications`** in an injectable `NotificationService`.
- It declares an Android channel (`routine_reminders`) and initializes both
  Android and iOS/macOS (`DarwinInitializationSettings`) notification options.
- `scheduleWeeklyRoutine(int routineId, int dayOfWeek)` schedules a **weekly
  repeating notification** ("Time for your Day N workout") using
  `RepeatInterval.weekly` with inexact, allow-while-idle scheduling.
- Android wiring in the manifest declares `POST_NOTIFICATIONS` and
  `RECEIVE_BOOT_COMPLETED` permissions plus the `ScheduledNotificationReceiver`
  and `ScheduledNotificationBootReceiver` receivers so reminders survive
  device reboots.

---

## Key Modules & Responsibilities

### Entry Points & Configuration

- **`main.dart` / `main_dev.dart`** — bootstrap with `AppConfig(name: 'dev',
  useMocks: true)`.
- **`main_local.dart`** — `useLocalDatabase: true` → Offline-First SQLite mode.
- **`main_qa.dart` / `main_prod.dart`** — HTTP mode pointing at QA / production
  API URLs.
- **`app.dart` (`NutriApp`)** — the composition root: instantiates the
  appropriate repositories (Mock → Local → HTTP) and builds the
  `MaterialApp` with `AppTheme.dark`.

### Models

- **`routine_models.dart`** — `Exercise` (id, name, muscleGroup, sets, reps,
  restSeconds) and `WorkoutDay` (id, weekday, focus, list of exercises), both
  with manual JSON serialization.
- **`diet_models.dart`** — `MealType` enum (`breakfast, lunch, dinner, snack`),
  `Meal` (name, mealType, calories, protein, carbs, fat) and `DailyMenu`
  (date, totalCalories, list of meals).

### Repositories

| Contract | HTTP impl | Local impl | Mock impl |
|---|---|---|---|
| `RoutineRepository.getWeeklyRoutine()` | `HttpRoutineRepository` (GET `/api/v1/routines/week`) | `LocalRoutineRepository` (SQLite) | `MockRoutineRepository` |
| `DietRepository.getDailyMenus()` | `HttpDietRepository` (GET `/api/v1/diets/menus`) | `LocalDietRepository` (SQLite) | `MockDietRepository` |

### UI Layer

- **`main_shell_page.dart`** — the tabbed shell (`Routines`, `Nutrition`,
  `Schedule`, `Profile`) that hosts the `NeumorphicFab` AI assistant entry.
- **`ai_chat_sheet.dart`** — the `AiChatSheet` bottom sheet: a neumorphic chat
  with user/assistant bubbles, a `TextEditingController` disposed in
  `dispose()`, an online guard (`AiService.ensureOnline`), and inline results
  from `RoutineRepository.generateRoutine`.
- **`neumorphic_fab.dart`** — a circular `NeumorphicContainer`-based floating
  action button with a semantic `Tooltip`.
- **Atoms / molecules** — reusable button, typography and neumorphic surface
  components; offline AI dialog.

---

## Environment Configuration

| Flavor | Entry point | Data source | Notes |
|---|---|---|---|
| dev | `main.dart` / `main_dev.dart` | Mocks | 500 ms simulated latency |
| local | `main_local.dart` | SQLite (Offline-First) | Seeds from mock data |
| qa | `main_qa.dart` | HTTP API | `https://qa-api.example.com` |
| prod | `main_prod.dart` | HTTP API | `https://api.example.com` |

---

## Tests

- **`test/widget_test.dart`** — verifies the dev config selects mocks and the
  dark theme scaffold.
- **`test/ui/neumorphic_fab_test.dart`** — verifies the AI FAB renders its icon
  and tooltip and invokes its callback.
- **`test/ui/ai_chat_sheet_test.dart`** — verifies the chat opens, ignores empty
  sends, renders online user/assistant messages, shows the offline dialog, and
  disposes its controller cleanly.
- **`test/features/m17_ai_assistant_widget_test.dart`** — verifies the shell
  FAB opens the chat and a full online ask/respond round-trip.
