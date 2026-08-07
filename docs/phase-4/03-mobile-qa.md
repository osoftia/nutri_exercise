# PHASE 4 — Flutter QA (Widget Tests + Offline Repository Unit Tests)

> **Author:** [Qwen] (Development & QA Lead)
> **Status:** Draft — pending approval
> **Depends on:** `docs/phase-4/02-mobile-logic.md`, `docs/phase-4/01-mobile-ui.md`
> **Scope:** Test layout, conventions, drift in-memory DB strategy, unit tests for the offline repositories/sync/interceptor/notifications, and widget/golden tests for the body map and atomic components.

---

## 1. Test Layout & Conventions

```text
mobile/test/
├── unit/
│   ├── db/
│   │   ├── drift_exercise_repository_test.dart
│   │   ├── drift_sync_queue_repository_test.dart
│   │   └── drift_schedule_repository_test.dart
│   ├── sync/
│   │   └── sync_engine_test.dart
│   ├── network/
│   │   └── ai_interceptor_test.dart
│   └── notifications/
│       └── notification_service_test.dart
└── widget/
    ├── atoms/   (ne_button_test.dart, …)
    ├── molecules/ (ne_muscle_region_test.dart, …)
    ├── organisms/ (ne_body_map_canvas_test.dart, …)
    └── pages/     (explore_page_test.dart, …)
```

- Naming: `<file under test>_test.dart`; test names as sentences: `'tapping a muscle region toggles selection and emits event'`.
- `testWidgets`, `group()`, fake time via `tester.pumpAndSettle()`, drift in-memory via `NativeDatabase.memory()`.

---

## 2. Unit Tests — Offline Repositories (drift in-memory)

```dart
class DbFixture {
  static Future<NutriDb> open() async {
    final db = NutriDb(NativeDatabase.memory());
    await db.migrations.migrate(db);   // or createAll
    return db;
  }
}

void main() {
  late NutriDb db;
  late DriftExerciseRepository repo;

  setUp(() async { db = await DbFixture.open(); repo = DriftExerciseRepository(db); });
  tearDown(() => db.close());

  test('upsertAll inserts and watchAll emits updated list', () async {
    await repo.upsertAll([Fixture.exercise('E1')]);
    final items = await repo.watchAll().first;
    expect(items.map((e) => e.id), contains('E1'));
  });

  test('getByMuscles filters by primary muscle', () async {
    await repo.upsertAll([Fixture.exercise('E1', muscle: 'CHEST'), Fixture.exercise('E2', muscle: 'BACK')]);
    final chest = await repo.getByMuscles({MuscleGroupId.chest});
    expect(chest.map((e) => e.id), ['E1']);
  });
}
```

### 2.1 Sync queue invariants

```dart
test('enqueue marks change PENDING and enqueue+markApplied keeps history consistent', () async {
  await queue.enqueue(change('C-1'));
  expect((await queue.pending()).first.status, SyncStatus.pending);

  await queue.markApplied('C-1');
  expect(await queue.pending(), isEmpty);
});

test('write through repo sets isLocalDirty and enqueues change in same transaction', () async {
  await repo.completeWorkout(CompletedWorkout(...));
  final dirty = await db.completedWorkouts.dirtyRows().get();
  final queued = await queue.pending();
  expect(dirty, isNotEmpty);
  expect(queued.single.entity, 'completedWorkout');
});
```

---

## 3. Unit Tests — Sync Engine

```dart
void main() {
  test('syncIfOnline when offline does not call the API', () async {
    final api = MockSyncApi();
    final engine = SyncEngine(queue, api, resolver, offlineConnectivity);
    await engine.syncIfOnline();
    verifyNever(api.push(any));
  });

  test('pushPending marks applied on server Applied', () async {
    api.pushReturns([ChangeResult.applied('C-1')]);
    await engine.pushPending();
    expect((await queue.pending()).map((c) => c.clientChangeId), isNot(contains('C-1')));
  });

  test('pushPending on Conflict keeps server row and records conflict for review', () async {
    api.pushReturns([ChangeResult.conflict('C-1')]);
    await engine.pushPending();
    final conflicts = await resolver.all();
    expect(conflicts.single.clientChangeId, 'C-1');
    // LWW: local row replaced by server payload
  });

  test('pushPending on network error retries (attempts+1, max 5)', () async {
    api.pushThrows(DioException.connectionError());
    await engine.pushPending();  // swallowed; no crash
    final c = (await queue.pending()).single;
    expect(c.attempts, 1);
  });
}
```

- `MockSyncApi` implements the `SyncApiClient` port; `FakeConnectivity` overrides `isOnline()`.

---

## 4. Unit Tests — AI Interceptor

```dart
void main() {
  test('offline with FAQ match returns local answer, does not hit API', () async {
    final ai = AiAssistant(dio, queue, offlineConnectivity);
    final reply = await ai.query('s1', 'suggest a chest workout');
    expect(reply.status, AiReplyStatus.answered);
    expect(reply.text, contains('chest'));
  });

  test('offline without FAQ match enqueues query and returns NETWORK_REQUIRED', () async {
    final reply = await ai.query('s1', 'custom odd question');
    expect(reply.status, AiReplyStatus.rejected);                 // NETWORK_REQUIRED
    expect((await queue.all()).single.message, 'custom odd question');
  });

  test('connection error race (offline mid-call) is caught, no crash', () async {
    dio.postThrows(DioExceptionType.connectionError);
    final reply = await ai.query('s1', 'hello');
    expect(reply.status, AiReplyStatus.rejected);
  });
}
```

---

## 5. Unit Tests — Notification Scheduling

```dart
test('scheduleWorkout computes next weekday/time instance and passes payload', () {
  // Freeze time (e.g. 2026-08-07 10:00 local, a Friday)
  // Schedule MONDAY 18:30 -> assert zonedSchedule called with next Monday 18:30 and payload refId
});

test('cancelSchedule maps schedule id to plugin cancel call', () { /* … */ });
```

- Use a fake `FlutterLocalNotificationsPlugin` (interface extracted behind `NotificationGateway`) to assert calls without platform channels.

---

## 6. Widget Tests

### 6.1 `NeMuscleRegion` (molecule)

```dart
testWidgets('tapping a region calls onTap and shows selected glow', (tester) async {
  var tapped = false;
  await tester.pumpWidget(MaterialApp(home: NeMuscleRegion(
    region: Fixture.chest, isSelected: false, onTap: () => tapped = true,
  )));
  await tester.tap(find.byType(NeMuscleRegion));
  expect(tapped, isTrue);
  expect(find.byKey(const Key('chest')), findsOneWidget);
});

testWidgets('selected region renders AnimatedContainer with primary glow', (tester) async {
  await tester.pumpWidget(... isSelected: true ...);
  final box = tester.widget<AnimatedContainer>(find.byType(AnimatedContainer));
  expect(box.decoration, isA<BoxDecoration>());   // BoxShadow present
});
```

### 6.2 `NeBodyMapCanvas` (organism)

```dart
testWidgets('FRONT/BACK toggle swaps region set and fires viewChange', (tester) async {
  final spy = <BodyView>[];
  await tester.pumpWidget(MaterialApp(home: NeBodyMapCanvas(
    view: BodyView.front, regions: [chest, back], selected: {MuscleGroupId.chest},
    onRegionToggle: (_) {}, onViewChange: spy.add,
  )));
  await tester.tap(find.byKey(const Key('view-toggle')));
  expect(spy.single, BodyView.back);
});

testWidgets('tapping empty silhouette space clears selection', (tester) async {
  // tap on background layer -> onRegionToggle never fired; parent store resets via canvas callback
});
```

### 6.3 `ExplorePage` (page, providers overridden)

```dart
testWidgets('page shows catalog skeleton while loading then tiles', (tester) async {
  // override ConnectivityProvider + ExerciseRepository with fakes
  await tester.pumpWidget(ProviderScope(overrides: [...], child: const NutriApp()));
  await tester.pump();
  expect(find.byType(NeSkeleton), findsWidgets);
  await tester.pumpAndSettle();
  expect(find.byType(NeExerciseTile), findsWidgets);
});

testWidgets('offline banner appears when connectivity is false', (tester) async {
  final conn = connectivityProvider.overrideWithValue(ValueNotifier(false));
  await tester.pumpWidget(... overrides: [conn] ...);
  expect(find.byType(NeSyncStatusBanner), findsOneWidget);
  expect(find.textContaining('Offline'), findsOneWidget);
});
```

### 6.4 Golden tests

- `matchesGoldenFile` for `NeButton`, `NeStatCard`, `NeMuscleRegion` (idle/selected), `NeBodyMapCanvas` (FRONT/BACK), `NeSyncStatusBanner` (offline/conflict).
- Goldens generated with `flutter test --update-goldens` against a fixed seed + `fontFamily: 'Ahem'` to avoid platform font drift.

---

## 7. CI Integration (`ci-mobile.yml`)

```bash
flutter pub get
flutter analyze
dart format --output=none --set-exit-if-changed .
flutter test --coverage
flutter build apk --debug
```

- Coverage gate (informational): ≥ 80% on `lib/core` (db, sync, network, notifications).

---

## 8. Approved Decisions & Open Decisions

**Approved (PHASE 4 gate):**
1. **Golden tests committed to the repo and enforced in CI** (`--update-goldens` only via explicit PR).
2. Drift schema: initial `createAll` for v1; `schemaVersion` migrations introduced on first schema change.

**Open:**
1. (none blocking)
