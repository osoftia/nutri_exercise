---

# MILESTONE 5 — Technical Blueprint
## Backend API Integration (Flutter ↔ C# .NET 8 + RAG + Ollama)

---

## 0. BDD ENTRY POINT

Per `mobile_app/BDD_WORKFLOW.md`, the acceptance criteria for this milestone
are defined FIRST in:

- **`mobile_app/test/features/m5_backend_integration.feature`**

The Coder MUST satisfy every Scenario in that file before considering the
milestone complete. This plan is the technical guide for meeting those
criteria. Key behaviors to deliver:

1. Request a routine from the API; **fall back to SQLite** if the network drops.
2. Handle **timeout and 500 errors** gracefully when the backend/Ollama is
   unreachable.
3. Persist API-generated routines into SQLite so they survive restarts.

---

## 1. CURRENT STATE (verified against the repo)

### 1a. Backend (already implemented, M1 backend work)

- C# .NET 8, Kestrel on port **5039** (see `backend/.../launchSettings.json`).
- Endpoints (`backend/NutriExercise.Api/Controllers/RoutineController.cs`):

| Method | Path | Request | Response |
|---|---|---|---|
| POST | `/api/routine/generate` | `{ "userPreferences": "Age: 28, Goal: build_muscle, ..." }` | `200 Routine` / `400` (empty prefs) / `500` (Ollama down) |
| GET | `/api/routine` | — | `200 List<Routine>` |
| GET | `/api/routine/{id}` | — | `200 Routine` / `404` |
| DELETE | `/api/routine/{id}` | — | `204` / `404` |

- `Routine` entity (`NutriExercise.Core/Entities/Routine.cs`):
  ```json
  { "id": 1, "name": "AI Generated Routine", "dayOfWeek": "Weekly", "description": "..." }
  ```
- AI pipeline: `OllamaAiService` → `http://localhost:11434/api/generate` (model
  `llama3`, stream off, 5-min timeout). RAG context uses PostgreSQL + pgvector.
- CORS policy `AllowFrontendClients` already permits `localhost`/`127.0.0.1`/
  `10.0.2.2` on ports 4200/5000/5039. **A device connecting from a LAN IP may
  need its origin added** (see Risks).

### 1b. Flutter (already present, needs M5 work)

- `pubspec.yaml` already has **`http: ^1.6.0`** — no new networking package
  strictly required.
- `lib/core/data/http_routine_repository.dart` exists:
  - `getWeeklyRoutine()` → GET `/api/routine`, falls back to `LocalRoutineRepository`.
  - `generateRoutine(prefs)` → POST `/api/routine/generate`, returns `description`,
    falls back to `LocalRoutineRepository.generateRoutine`.
  - Maps the backend `Routine` onto `WorkoutDay` via `_fromBackendRoutine`
    (currently leaves `exercises` empty).
- `lib/core/constants/api_constants.dart`: `defaultPort = 5039`,
  `baseUrl` = `--dart-define=API_BASE_URL` override → Android emulator
  `192.168.1.2:5039` → else `localhost:5039`. Endpoint paths
  `/api/routine/generate` and `/api/routine`.
- `EnvironmentProvider._buildRoutineRepository()` already wires
  `HttpRoutineRepository(baseUrl, fallback: LocalRoutineRepository())` for
  `qa`/`prod` flavors.

> **Gap for M5:** the current HTTP path does not **persist API results to
> SQLite** and does not map the AI description back into structured
> `Exercise`s. M5 introduces `ApiRoutineRepository` to close this gap.

---

## 2. PACKAGE INTEGRATION

### 2a. Decision: `http` vs `dio`

| Option | Pros | Cons |
|---|---|---|
| `http` (present) | Already a dependency, zero new deps, sufficient for 2 endpoints, matches existing code | Manual timeouts/retry plumbing |
| `dio` | Interceptors, retry, timeout config, logging | New dependency; API surface differs from existing code |

**Decision: keep `http`.** The milestone needs only timeout + status-code
handling + JSON decode, all native to `http`. Introduce `dio` only if M6+ needs
interceptors, download progress, or retry policies.

No `pubspec.yaml` change required. If a retry/backoff helper is desired, it
lives inside `ApiRoutineRepository` using `Timer`/loops — no package needed.

---

## 3. `ApiRoutineRepository` (new file: `lib/core/data/api_routine_repository.dart`)

### 3a. Class Shape

```dart
class ApiRoutineRepository implements RoutineRepository {
  ApiRoutineRepository(
    this.baseUrl, {
    RoutineRepository? fallback,
    LocalRoutineRepository? local,      // used for persistence
    http.Client? client,                // injectable for tests
    Duration timeout = const Duration(seconds: 10),
  });
}
```

Responsibilities:

- **`getWeeklyRoutine()`** — try `GET /api/routine`; on success map each
  `Routine` JSON to `WorkoutDay`; on any failure/timeout/error status → return
  `fallback.getWeeklyRoutine()` (SQLite).
- **`generateRoutine(prefs)`** — try `POST /api/routine/generate`; on success:
  1. Parse the `Routine` response into a `WorkoutDay`.
  2. **Persist it to SQLite** via `LocalRoutineRepository.saveRoutine(day)`
     (transactional `saveWorkoutDay`, `isGenerated: true`).
  3. Return the AI `description` for the result dialog.
  On failure → `fallback.generateRoutine(prefs)` (already persists to SQLite)
  and the dialog reports the offline source.

### 3b. Base URL parameterization (Mac local IP)

The Mac hosting the backend + Ollama is reached from a physical device /
emulator via its **LAN IP**, never `localhost`. Precedence (highest first):

1. **`--dart-define=API_BASE_URL=http://<mac-ip>:5039`** — recommended for
   physical devices.
2. **`API_BASE_URL` from the environment / `FlavorFactors`** for CI or QA.
3. **`ApiConstants.baseUrl`** default (emulator `10.0.2.2` / `192.168.1.2`).

Recommended launch for M5 local testing:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.42:5039
```

`ApiConstants.defaultPort` stays `5039`. Keep the existing
`withDartDefineOverrides()` mechanism as the wiring point so all flavors
inherit the override automatically.

---

## 4. JSON SERIALIZATION MAPPING (backend ↔ Flutter)

### 4a. Inbound contract (C# `Routine` → Flutter)

| C# field | JSON key | Flutter model | Mapping |
|---|---|---|---|
| `Id` | `id` | `WorkoutDay.id` | direct `int` |
| `DayOfWeek` | `dayOfWeek` | `WorkoutDay.weekday` | direct `String` |
| `Name` | `name` | `WorkoutDay.focus` | direct `String` |
| `Description` | `description` | `WorkoutDay.exercises` + dialog text | see 4b |
| (future) `Exercises` | `exercises` | `List<Exercise>` | see 4c |

Add a dedicated mapper (e.g. `_fromBackendRoutine(Map<String, dynamic>)`) that
reuses the existing `Exercise.fromJson`/`WorkoutDay.fromJson` shapes where the
backend already matches them.

### 4b. Mapping the AI description to exercises

The backend currently returns the routine as **free-form AI text** in
`description` (no structured exercise array). M5 introduces a best-effort
parser, `parseDescriptionToExercises(String text)`, that:

- Extracts exercises using a line-oriented heuristic
  (`Exercise: <name>` / `<name> — <sets>x<reps>`, etc.).
- Falls back to a **catalog lookup**: if the AI mentions a known exercise name
  from `mock_routine_payload.dart`, the canonical `muscleGroup`, `sets`,
  `reps`, `restSeconds`, `weight` metadata is attached.
- Produces an empty list if nothing is parseable → the routine still persists
  with the description text and zero structured exercises.

Design sketch:

```dart
WorkoutDay mapBackendRoutine(Map<String, dynamic> json, String description) {
  final parsed = parseDescriptionToExercises(description);
  return WorkoutDay(
    id: json['id'] as int,
    weekday: json['dayOfWeek'] as String,
    focus: json['name'] as String,
    exercises: parsed,
  );
}
```

### 4c. Contract evolution (optional, M5+)

The clean long-term fix is for the backend to emit a structured `exercises`
array (`{ name, muscleGroup, sets, reps, restSeconds, weight }`) from
`RoutineController.Generate`. If that lands in M5 scope, add a `GET`/`POST`
payload field and map it straight onto `Exercise.fromJson`. The client mapper
prefers structured `exercises` when present and falls back to 4b parsing
otherwise — keeps both old and new backend versions working.

---

## 5. OFFLINE-FIRST FLOW (Wizard → API → SQLite → UI)

```
WizardPage
  └─ RoutineWizardProvider.generateRoutine(prefs)
       └─ ApiRoutineRepository.generateRoutine(prefs)      [Flavor qa/prod]
            ├─ POST /api/routine/generate  ── SUCCESS ─┐
            │         │                                 │
            │         └─ parse Routine → WorkoutDay     │
            │              └─ LocalRoutineRepository    │
            │                 .saveRoutine(day)  → SQLite (is_generated=1)
            │                       └─ returns description → result dialog
            │
            └─ TIMEOUT / 5xx / parse error
                 └─ LocalRoutineRepository.generateRoutine(prefs)
                      └─ SQLite (offline, is_generated=1)
                      └─ description notes "generated offline"

Apply to Dashboard
  └─ RoutineProvider.loadRoutine()
       └─ ApiRoutineRepository.getWeeklyRoutine()
            ├─ GET /api/routine → map list → UI
            └─ failure → LocalRoutineRepository.getWeeklyRoutine() → SQLite → UI
```

### 5a. Provider wiring (no breaking change)

`EnvironmentProvider._buildRoutineRepository()` switches its Http branch to the
new class:

```dart
if (_config.useLocalDatabase) return LocalRoutineRepository();
return ApiRoutineRepository(
  _config.apiBaseUrl.isEmpty ? ApiConstants.baseUrl : _config.apiBaseUrl,
  fallback: LocalRoutineRepository(),
);
```

`RoutineProvider` / `RoutineWizardProvider` are unchanged — they keep
consuming `RoutineRepository`. The offline-first logic lives entirely inside
`ApiRoutineRepository`.

### 5b. Result dialog offline notice

`generateRoutine` returns a `String`. When the fallback path is taken, prefix
the returned text with a marker (e.g. `[Offline] Generated locally...`) so
`generated_routine_dialog.dart` can render a visible offline badge. No dialog
code changes required if the marker is embedded in the string; a small dialog
tweak is optional.

---

## 6. ERROR HANDLING MATRIX

| Condition | Detected by | Behavior |
|---|---|---|
| Network drop (SocketException) | `catch` on request | `getWeeklyRoutine` → SQLite; `generateRoutine` → SQLite fallback + offline notice |
| Timeout (>10s) | `.timeout(Duration(seconds: 10))` | Same as network drop; no partial write |
| HTTP 500 (Ollama down / RAG error) | `statusCode == 500` | Not a crash; fallback to SQLite |
| HTTP 400 (empty/malformed prefs) | `statusCode == 400` | Surface friendly validation message; do NOT persist |
| HTTP 404 (GET by id) | `statusCode == 404` | Treated as empty result, not an error |
| Malformed body (parse throw) | `jsonDecode` / cast try-catch | Treat as failure → fallback |
| Success | `200` + valid body | Parse → persist to SQLite → return |

Rule: **any** failure of the API path degrades to the SQLite fallback. The app
never shows a raw error screen for the remote path (matches
`m5_backend_integration.feature`).

---

## 7. FILE MANIFEST — New & Modified

| Action | Path | Purpose |
|---|---|---|
| **CREATE** | `lib/core/data/api_routine_repository.dart` | Offline-first API repository (GET + generate + persist to SQLite) |
| **CREATE** | `lib/core/data/description_parser.dart` | Best-effort AI-description → `List<Exercise>` parser |
| **MODIFY** | `lib/core/constants/api_constants.dart` | Ensure LAN-IP override path is documented/kept (`API_BASE_URL`) |
| **MODIFY** | `lib/core/providers/environment_provider.dart` | Swap `HttpRoutineRepository` → `ApiRoutineRepository` |
| **MODIFY** | `test/features/m5_backend_integration.feature` | Acceptance criteria (written first, BDD) |
| **WRITE** | `m5_execution_changes.log` | Execution summary (Coder, end of milestone) |

> Optional: delete/replace `http_routine_repository.dart` if fully superseded,
> or keep it as a thin alias. Prefer replacement to avoid dead code.

---

## 8. DEPENDENCY GRAPH

```
ApiRoutineRepository
  ├── package:http (timeout, GET/POST)
  ├── ApiConstants (baseUrl, paths)
  ├── WorkoutDay/Exercise (models + mappers)
  ├── LocalRoutineRepository (SQLite persistence + fallback)
  └── description_parser.dart (AI text → exercises)

EnvironmentProvider
  └── ApiRoutineRepository(baseUrl, fallback: LocalRoutineRepository)

RoutineProvider / RoutineWizardProvider
  └── consume RoutineRepository (unchanged)
```

---

## 9. IMPLEMENTATION ORDER (for the Coder)

```
PHASE 1 — Contract foundation
  ├── Step 1.1: Add description_parser.dart (+ unit-testable pure function)
  └── Step 1.2: Define mapper (backend Routine JSON → WorkoutDay)

PHASE 2 — ApiRoutineRepository
  ├── Step 2.1: Implement getWeeklyRoutine() with timeout + fallback
  ├── Step 2.2: Implement generateRoutine() → parse → persist to SQLite → return
  └── Step 2.3: Wire offline notice in returned description

PHASE 3 — Wiring
  ├── Step 3.1: EnvironmentProvider → ApiRoutineRepository
  ├── Step 3.2: Verify dart-define base URL to Mac LAN IP
  └── Step 3.3: Manual smoke test against running backend

PHASE 4 — Verification
  ├── Step 4.1: flutter analyze (0 new warnings)
  ├── Step 4.2: Manual walkthrough of every Scenario in m5 .feature
  └── Step 4.3: Write m5_execution_changes.log
```

---

## 10. TESTING CHECKLIST (maps to the .feature)

| # | Scenario | Expected |
|---|---|---|
| 1 | API generate success | Routine parsed → saved to SQLite → UI refresh → dialog shows description |
| 2 | API routine list success | Dashboard renders API routines |
| 3 | Network drop on generate | SQLite fallback → offline notice → UI updates |
| 4 | Network drop on list | SQLite fallback → previously saved routines shown, no error screen |
| 5 | Timeout | Request aborted → fallback → routine still delivered |
| 6 | Backend 500 (Ollama down) | No crash → fallback → local routine |
| 7 | Backend 400 | Friendly validation message, nothing persisted |
| 8 | Malformed body | Treated as failure → fallback |
| 9 | Restart offline | Saved API routine survives via SQLite |

---

## 11. RISKS & NOTES

- **LAN IP reachability**: the Mac's firewall must allow inbound on 5039, and
  the CORS policy must include the device origin. On iOS, ATS blocks plain HTTP
  to LAN IPs unless `NSAllowsArbitraryLoads` (debug) is set. Verify with the
  backend running before debugging Flutter.
- **Ollama latency**: first inference on `llama3` can take 30s+. The 10s
  client timeout is for the HTTP layer; the backend uses a 5-min Ollama
  timeout. If the client times out first, the user gracefully gets the offline
  routine — acceptable and covered by Scenario "Backend request times out".
- **Description parsing is heuristic**: AI text formats vary. The catalog
  lookup guarantees muscle metadata for known exercises; unknown ones may land
  with default values. Structured `exercises` from the backend (4c) is the
  durable fix.
- **Idempotency**: API-generated `WorkoutDay.id` uses the backend `Routine.id`
  for the SQLite row id; re-generating replaces that row via the M4 upsert
  (`ConflictAlgorithm.replace`), so no duplicates accumulate.
- **Flavor gating**: M5 behavior only activates on `qa`/`prod` flavors.
  `dev` (mock) and `local` (SQLite) are untouched — the M1–M4 feature files
  must keep passing.

---