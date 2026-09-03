# Milestone 21 — Local Notifications & Text Logger

> **Author:** @Architect
> **Status:** Ready for @Coder implementation (strict TDD per `.opencode.md`)
> **Branch:** `feature/m21-local-notifications`
> **Contract:** `mobile_app/test/features/m21_local_notifications.feature`

## 0. Milestone context & pivot

The `.NET` backend milestone is **paused**. This milestone is **mobile-only**:
no backend, no new HTTP endpoints, no Ollama interaction. Everything described
here runs on-device using `flutter_local_notifications` (already a dependency)
and the existing offline-first SQLite stack (`DatabaseHelper`).

Goal in one sentence: **every day at 8:00 PM the app posts a local notification
asking "What did you eat and train today?"; tapping it drops the user straight
into a small text sheet where they type and save a one-paragraph daily summary
that persists locally.**

---

## 1. Current state (what already exists)

| Concern | Status |
|---|---|
| `flutter_local_notifications: ^19.4.0` | Already in `pubspec.yaml`. |
| `NotificationService` | Exists at `lib/core/services/notification_service.dart` with `initialize()` and a *weekly* `scheduleWeeklyRoutine()`. No daily schedule, no tap handling. |
| Android manifest | Already declares `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`, and the `ScheduledNotificationReceiver` / `ScheduledNotificationBootReceiver` receivers. |
| `timezone` package | Present only as a transitive dependency — must be promoted to a direct dependency for `zonedSchedule`. |
| Navigation | `app.dart` builds `MaterialApp` with `home: MainShellPage(...)`, **no** `navigatorKey`, **no** named routes. Sheets are opened imperatively (`showModalBottomSheet`, see `ai_chat_sheet.dart`). |
| Persistence | `DatabaseHelper` (SQLite, currently **version 2**) with tables `routines`, `diets`, `notification_prefs`, `profile`, `projection_plan`, `projection_milestone`. |
| State | `ChangeNotifier` controllers in `core/state/` wired by constructor injection from `app.dart` (e.g. `ScheduleController`, `ProjectionController`). |

No daily-log model, repository, controller, or sheet exists yet.

---

## 2. Notification scheduling

### 2.1 New channel & schedule

- Add a **new** Android notification channel (distinct from the existing
  `routine_reminders`): `daily_log_reminders` — "Daily check-in".
- Schedule a **daily repeating** notification at **20:00 local time** using
  `zonedSchedule` with `matchDateTimeComponents: DateTimeComponents.time`
  (repeats at the same time every day), rather than `periodicallyShow` (which
  cannot pin a wall-clock time).
- Use `AndroidScheduleMode.inexactAllowWhileIdle` (mirrors the existing weekly
  reminder) so no exact-alarm special permission is required.
- Title/body: **"Daily check-in"** / **"What did you eat and train today?"**.

### 2.2 Timezone bootstrap (required for `zonedSchedule`)

`zonedSchedule` needs a `tz.TZDateTime`. This requires:

1. Promote `timezone` to a direct dependency (add `flutter_timezone` to resolve
   the device's IANA zone id).
2. A one-time bootstrap at startup: `tz.initializeTimeZones()` then
   `tz.setLocalLocation(tz.getLocation(<device zone id>))` (fall back to
   `tz.local` / UTC if the device id cannot be resolved).

### 2.3 Permissions

- Android 13+ (`API 33`) requires runtime `POST_NOTIFICATIONS` permission.
  Before scheduling, call
  `resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission()`.
- If permission is denied, **skip scheduling silently** (no crash) — see the
  "denied permission" scenario. iOS/macOS request on `initialize()` (already
  configured).

### 2.4 Service API (design contract — no implementation)

Extend `NotificationService` (keep the weekly method for backwards compat):

```dart
class NotificationService {
  Future<void> initialize({void Function(String? payload)? onTap});
  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
  });
  Future<NotificationLaunchDetails> launchDetails();
}
```

- `initialize` now registers an `onDidReceiveNotificationResponse` callback so a
  tap while running is routed (see §3).
- `scheduleDailyReminder` is **idempotent**: canceling the previous daily
  schedule (by id/name) before re-scheduling so relaunching the app never
  stacks duplicate reminders.

---

## 3. Routing flow (tap → daily log sheet)

The app has no route table, so use a **navigator key + pending-action
controller** — the smallest change that fits the existing imperative-sheet
pattern.

### 3.1 Pieces

1. **`navigatorKey`** — a `GlobalKey<NavigatorState>` added to `MaterialApp`.
2. **`NotificationNavigationController`** (`ChangeNotifier`) holding a pending
   action, e.g.:

   ```dart
   enum NotificationAction { openDailyLog }

   class NotificationNavigationController extends ChangeNotifier {
     NotificationAction? pending;
     void requestDailyLog() { pending = NotificationAction.openDailyLog; notifyListeners(); }
     void consume() { pending = null; }
   }
   ```

3. A listener (in `MainShellPage`, which already hosts the shell `Scaffold`)
   that watches the controller and, on `openDailyLog`, calls
   `showDailyLogSheet(...)` then `consume()`.

### 3.2 Two tap paths

- **App running / backgrounded** — the `onDidReceiveNotificationResponse`
  callback → `requestDailyLog()` → the shell opens the sheet immediately.
- **Cold start** — `getNotificationAppLaunchDetails()` at startup; if
  `didNotificationLaunchApp` and the payload is the daily-check-in id, set the
  pending action before the first frame so the sheet opens once the shell is
  mounted.

Both paths funnel through the same `requestDailyLog()` → sheet → `consume()`
pipeline, which keeps the widget test surface small.

---

## 4. Domain model & persistence — the "Text Logger"

### 4.1 Model

A single new model `DailyLog` (date + free-text summary):

```dart
class DailyLog {
  final String date;   // 'YYYY-MM-DD'
  final String text;
}
```

(Follow the manual `toJson`/`fromJson` style used by `routine_models.dart` /
`diet_models.dart`.)

### 4.2 Persistence

- Bump `DatabaseHelper` `_dbVersion` **2 → 3**; add an `onUpgrade` branch.
- New table:

  ```sql
  CREATE TABLE daily_logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    date TEXT NOT NULL UNIQUE,
    text TEXT NOT NULL
  )
  ```

  `date` is unique so `save` is an upsert (`ConflictAlgorithm.replace`) — one
  summary per day.

### 4.3 Repository & controller

- `DailyLogRepository` (abstract contract) with `getByDate(String date)` and
  `save(DailyLog log)`; `LocalDailyLogRepository` (SQLite, mirrors
  `LocalRoutineRepository`) + `MockDailyLogRepository` for tests/dev flavor.
- `DailyLogController` (`ChangeNotifier`) with:
  - `Future<void> load(String date)` — populates the current text (or empty);
  - `Future<bool> save(String text)` — trims, rejects empty, persists, notifies;
  - `String get text`, `bool get isSaving`, `String? get errorMessage`.

### 4.4 Sheet UI

- New `DailyLogSheet` in `lib/ui/molecules/daily_log_sheet.dart` (mirrors
  `AiChatSheet`): a `NeumorphicContainer` modal bottom sheet with a multiline
  `TextField` (key `daily_log_input`), `Cancel` / `Save` (key
  `daily_log_save`), and a `showDailyLogSheet(context, controller)` helper.
- The sheet owns and disposes its `TextEditingController` (same hygiene as
  `AiChatSheet`). Reopening for the same day pre-fills any existing text.

---

## 5. Startup wiring

`app.dart` (`NutriApp`) becomes the composition root for the new pieces:

1. `WidgetsFlutterBinding.ensureInitialized()` + timezone bootstrap (§2.2).
2. Construct `NotificationService`, `DailyLogController` (+ repository, chosen
   by `AppConfig` as mock vs local), and `NotificationNavigationController`.
3. `initialize()` notifications with the tap callback; request Android
   permission; `scheduleDailyReminder(hour: 20, minute: 0)`.
4. Attach `navigatorKey` to `MaterialApp` and pass the two new controllers into
   `MainShellPage` (consistent with the existing constructor-injection style).

---

## 6. Files

**New**
- `mobile_app/lib/core/models/daily_log.dart` — `DailyLog` model.
- `mobile_app/lib/core/data/daily_log_repository.dart` — abstract contract.
- `mobile_app/lib/core/data/local_daily_log_repository.dart` — SQLite impl.
- `mobile_app/lib/core/data/mock_daily_log_repository.dart` — mock impl.
- `mobile_app/lib/core/state/daily_log_controller.dart` — `ChangeNotifier`.
- `mobile_app/lib/core/state/notification_navigation_controller.dart` — pending
  tap action.
- `mobile_app/lib/ui/molecules/daily_log_sheet.dart` — sheet + open helper.

**Modified**
- `mobile_app/lib/core/services/notification_service.dart` — add
  `scheduleDailyReminder`, tap callback, launch-details access, idempotency.
- `mobile_app/lib/core/database/database_helper.dart` — DB version 3 +
  `daily_logs` table + `upsert`/`get` helpers.
- `mobile_app/lib/app.dart` — construct/wire the new services + `navigatorKey`.
- `mobile_app/lib/ui/pages/main_shell_page.dart` — accept the controllers, watch
  `NotificationNavigationController`, open the sheet on tap/launch.
- `mobile_app/pubspec.yaml` — add `timezone` (and `flutter_timezone`).

**No backend / web-portal changes** (milestone is mobile-only).

---

## 7. Testability (BDD → TDD mapping)

| Gherkin scenario | Target test(s) |
|---|---|
| Daily reminder scheduled for 20:00 + body | `notification_service_test.dart` — fake platform records `zonedSchedule` args (time + body + `DateTimeComponents.time`). |
| Repeats every day | Assert `matchDateTimeComponents == DateTimeComponents.time`. |
| Idempotent scheduling | Fake platform asserts `cancel` called before re-schedule; only one pending. |
| Tap → sheet (running & cold start) | `notification_navigation_controller` unit test (`requestDailyLog` sets pending; `consume` clears) + `main_shell_page` widget test opens the sheet on pending action. |
| Save persists / pre-fill / empty rejected | `daily_log_controller_test.dart` (save round-trip, trim/reject empty) + `local_daily_log_repository_test.dart` (SQLite in-memory) + `daily_log_sheet_test.dart` (widget). |
| Denied permission → no crash, no schedule | `notification_service_test.dart` — fake platform returns permission denied; service returns without throwing. |

Follow the existing fake-platform pattern already used in
`test/services/notification_service_test.dart` (a `FlutterLocalNotificationsPlatform`
subclass set via `FlutterLocalNotificationsPlatform.instance`).

---

## 8. Out of scope

- Backend persistence of logs or notifications (backend milestone paused).
- Editing/deleting past logs, a full journal history UI, or streak rewards.
- Exact-alarm (API 31 `SCHEDULE_EXACT_ALARM`) guarantees — inexact scheduling is
  sufficient for an 8 PM nudge.
- Timezone picker / user-configurable reminder time (hard-coded 20:00 for now,
  but parameterised in `scheduleDailyReminder` for a later settings toggle).
- Rich notification actions (inline "quick reply"), images, or deep links beyond
  opening the log sheet.
