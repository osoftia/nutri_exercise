# PHASE 4 — Flutter Mobile App (Core Logic: SQLite, Sync, AI Interceptor, Notifications)

> **Author:** [Qwen] (Development & QA Lead)
> **Status:** Draft — pending approval
> **Depends on:** `docs/phase-1/02-sdd-contracts.md` §4 (sync) §5.2 (SQLite schema), `docs/phase-4/01-mobile-ui.md`
> **Scope:** SQLite repository setup (drift), offline sync engine, the AI-query network interceptor, and local push notification scheduling.

---

## 1. Flutter Project Layout

```text
mobile/
├── lib/
│   ├── main.dart                       # runApp + bootstrap
│   ├── app/                            # MaterialApp, theme (tokens), routes
│   ├── core/
│   │   ├── db/                         # drift: database.dart, tables.dart
│   │   ├── network/                    # ApiClient, ConnectivityService, AiInterceptor
│   │   ├── sync/                       # SyncEngine, SyncQueueRepository, ConflictResolver
│   │   ├── notifications/              # NotificationService (flutter_local_notifications)
│   │   └── state/                      # riverpod providers (offline-first store)
│   ├── features/
│   │   ├── onboarding/  explore/  workouts/  nutrition/  schedule/  assistant/  profile/
│   └── atoms/ molecules/ organisms/ templates/ pages/   # Atomic Design (Gemma spec)
├── assets/vectors/                     # per-muscle SVG (shared SPG data)
└── test/
    ├── unit/                           # repos, sync, interceptor, notifications
    └── widget/                         # atoms/molecules/organisms/pages goldens + interactions
```

Packages: `drift` + `drift_flutter`, `sqflite` (native fallback), `flutter_svg`, `riverpod` (state), `connectivity_plus`, `flutter_local_notifications`, `timezone`, `dio` (HTTP), `uuid`.

---

## 2. SQLite Data Layer (drift)

### 2.1 Tables (mirror contract §5.2)

```dart
class Profiles extends Table { TextColumn get id => text()(); /* … profile fields */ }
class MuscleGroups extends Table { TextColumn get id => text()(); TextColumn get svgPathId => text()(); }
class Exercises extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get primaryMuscleId => text().references(MuscleGroups, #id)();
  TextColumn get secondaryMusclesJson => text().withDefault(const Constant('[]'))();
  TextColumn get equipment => text()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  BoolColumn get isLocalDirty => boolean().withDefault(const Constant(false))();
}
class CompletedWorkouts extends Table { /* id, planId, performedAtUtc, isLocalDirty */ }
class Schedules extends Table { /* … + isLocalDirty */ }
class SyncQueue extends Table {
  TextColumn get clientChangeId => text()();
  TextColumn get entity => text()();
  TextColumn get operation => text()();
  TextColumn get entityId => text()();
  TextColumn get payloadJson => text()();
  TextColumn get status => text().withDefault(const Constant('PENDING'))();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get changedAtUtc => text()();
  @override Set<Column> get primaryKey => {clientChangeId};
}
class SyncConflicts extends Table { /* clientChangeId, entity, entityId, localJson, serverJson, resolved */ }
class AiOfflineQueue extends Table { /* sessionId, message, createdAtUtc, retryCount */ }
class Meta extends Table { TextColumn get key => text()(); TextColumn get value => text()(); @override Set<Column> get primaryKey => {key}; }
```

### 2.2 Repository pattern (ports + drift impl)

```dart
abstract class ExerciseRepository {
  Stream<List<Exercise>> watchAll();
  Future<List<Exercise>> getByMuscles(Set<MuscleGroupId> muscles);
  Future<void> upsertAll(List<Exercise> exercises);
}
class DriftExerciseRepository implements ExerciseRepository { final NutriDb _db; /* … */ }

abstract class SyncQueueRepository {
  Future<List<SyncChange>> pending();
  Future<void> enqueue(SyncChange change);
  Future<void> markApplied(String clientChangeId);
  Future<void> markConflict(String clientChangeId, String serverJson);
}
```

- Every write through a repository sets `isLocalDirty = true` and enqueues a `SyncChange` (same transaction) so the queue is always consistent with local state.

---

## 3. Offline Sync Engine

### 3.1 `SyncEngine` (state machine)

```dart
class SyncEngine {
  final SyncQueueRepository _queue;
  final SyncApiClient _api;
  final ConflictResolver _resolver;
  final ConnectivityService _connectivity;

  Future<void> syncIfOnline() async {
    if (!(await _connectivity.isOnline())) return;      // stay offline silently
    await pushPending();
    await pullIncremental();
  }

  Future<void> pushPending() async {
    final batch = await _queue.pending();
    if (batch.isEmpty) return;
    final result = await _api.push(batch);              // POST /api/v1/sync/push
    for (final r in result.results) {
      switch (r.status) {
        case Applied: await _queue.markApplied(r.clientChangeId);
        case Rejected: await _queue.markApplied(r.clientChangeId);      // terminal (invalid payload)
        case Conflict:
          await _resolver.resolve(r);                    // LWW: if server newer -> keep server, drop local
      }
    }
  }

  Future<void> pullIncremental() async {
    final cursor = await _meta.get('syncCursor');
    final serverChanges = await _api.pull(sinceUtc: cursor);   // POST /api/v1/sync/pull
    for (final change in serverChanges) await applyServerChange(change);
    await _meta.set('syncCursor', serverChanges.lastTimestamp);
  }
}
```

- `applyServerChange` upserts into the matching repository with `isLocalDirty = false`.
- LWW: for conflicts where server row is newer, local changes are discarded and replaced by server payload; the discarded payload is stored in `sync_conflicts` for the review UI.
- Retry: `pending()` where `status=PENDING and attempts<5`, enqueued via exponential backoff timer when connectivity returns (`connectivity_plus` stream).

### 3.2 Connectivity-driven UI state

```dart
final connectivityProvider = StreamProvider<bool>((ref) {
  return Connectivity().onConnectivityChanged
      .map((r) => r.any((c) => c != ConnectivityResult.none))
      .distinct();
});
```

- `NeSyncStatusBanner` reads this provider: offline → amber "Offline — queued N changes"; sync running → progress; conflict → red "Review changes" deep link.

---

## 4. AI Query Network Interceptor

Goal: prevent crashes and guide the user when offline (contract §4.4).

```dart
class AiAssistant {
  final Dio _dio;
  final AiOfflineQueueRepository _offlineQueue;
  final ConnectivityService _connectivity;

  Future<AiReply> query(String sessionId, String message) async {
    if (!(await _connectivity.isOnline())) {
      final local = LocalFaq.maybeAnswer(message);          // curated FAQ keywords
      if (local != null) return local;                      // answer from offline FAQ
      await _offlineQueue.enqueue(sessionId, message);      // persist for later
      return AiReply.rejected('Connect to the internet to use the AI assistant.'); // NETWORK_REQUIRED
    }
    try {
      return await _dio.post('/api/v1/ai/query', data: {...});
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError) {
        // race: went offline between check and call — same graceful path
        await _offlineQueue.enqueue(sessionId, message);
        return AiReply.rejected('Connect to the internet to use the AI assistant.');
      }
      rethrow;                                               // other errors surfaced as typed ApiError
    }
  }
}
```

- `AiReply.rejected` renders the `NETWORK_REQUIRED` banner in `NeAIAssistantPanel`; **no unhandled exceptions reach the UI.**
- Offline queue flush on next successful sync.

---

## 5. Local Notification Scheduling

```dart
class NotificationService {
  Future<void> init() async {
    await _plugin.initialize(settings: const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    ));
    // timezone set from device: tz.setLocalLocation(await tz.getLocation(tz.local.name))
  }

  Future<void> scheduleWorkout(Schedule s) async {
    await _plugin.zonedSchedule(
      id: s.id.hashCode,
      title: 'Workout time',
      body: 'Your ${s.activityType} starts now',
      scheduledDate: _nextInstanceOf(s.weekday, s.timeLocal),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails('workouts', 'Workout reminders', importance: Importance.high),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: s.refId,                                        // deep link /workouts/:id
    );
  }

  Future<void> cancelSchedule(Schedule s) => _plugin.cancel(s.id.hashCode);
}
```

- On notification tap: `onDidReceiveNotificationResponse` → `Navigator` pushes `/workouts/:id` (payload `refId`).
- On login/profile change: cancel all, re-schedule from local `schedules` table.
- Schedule rows are kept in SQLite; notifications are re-armed on app launch (source of truth = DB, not OS).

---

## 6. Boot Sequence

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = NutriDb();                       // drift open + migrations
  await NotificationService().init();
  await SyncEngine().syncIfOnline();          // best-effort, non-blocking
  runApp(const NutriApp());
}
```

---

## 7. Approved Decisions & Open Decisions

**Approved (PHASE 4 gate):**
1. SQLite layer: **drift** (`drift_flutter`, `NativeDatabase`).

**Open:**
1. Offline FAQ scope: static keyword map now, expandable to bundled embeddings later?
