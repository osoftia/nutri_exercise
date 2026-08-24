# Milestone 1 Blueprint — Robust Mock System & Environment Switch

## 1. Inspection Findings

**`pubspec.yaml`** (`nutri_mobile_app`, Flutter SDK `>=3.7.0 <4.0.0`):
- Runtime deps: `http ^1.6.0`, `sqflite ^2.4.1`, `path_provider ^2.1.5`, `connectivity_plus ^7.3.1`, `flutter_local_notifications ^19.4.0`.
- No new packages required for Milestone 1 (env switch + mocks are pure Dart). No `freezed`/`json_serializable` — keep manual `fromJson`/`toJson` per existing convention.

**`ARCHITECTURE.md`**: layered `core/` (config, data, mocks, models) + `ui/` atomic design; DI is constructor-based at `NutriApp` (`app.dart:16`); repository selection order Mock → Local → HTTP; flavors `dev/local/qa/prod` via separate entry points.

**Current state (already partially implemented)**: `environment_config.dart`, `mock_routine_payload.dart`, and the `useMockApi` toggle in `app.dart:26` already exist. Blueprint below formalizes and completes them.

## 2. Environment Configuration Architecture

**File:** `lib/core/config/environment_config.dart`

```
EnvironmentConfig (immutable, const-constructible)
├── name: String                 # 'dev' | 'local' | 'qa' | 'prod'
├── useMockApi: bool             # THE toggle: true → Mock repositories
├── useLocalDatabase: bool       # true → SQLite repositories (local flavor)
├── apiBaseUrl: String           # '' → falls back to ApiConstants.baseUrl
├── mockLatency: Duration        # default 500 ms (simulated network delay)
├── withDartDefineOverrides()    # reads --dart-define USE_MOCK_API / API_BASE_URL
└── static factories: dev(), local(), qa(), prod()
```

Resolution contract (implemented in `app.dart` `NutriApp.build`):
1. `config.withDartDefineOverrides()` first (runtime override wins: `USE_MOCK_API=true/false`).
2. If `useMockApi` → `MockDietRepository` + `MockRoutineRepository(latency: mockLatency)`.
3. Else if `useLocalDatabase` → `Local*Repository` (sqflite).
4. Else → `Http*Repository(apiBaseUrl or ApiConstants.baseUrl, fallback: Local*Repository())`.

`AppConfig extends EnvironmentConfig` kept as compatibility shim (`useMocks` → `@Deprecated`, maps to `useMockApi`).

Toggle matrix:

| Flavor | Entry point | useMockApi | useLocalDatabase | Data source |
|---|---|---|---|---|
| dev | `main.dart` / `main_dev.dart` | true | false | Mocks (500 ms latency) |
| local | `main_local.dart` | false | true | SQLite seeded from mocks |
| qa | `main_qa.dart` | false | false | HTTP + Local fallback |
| prod | `main_prod.dart` | false | false | HTTP + Local fallback |

## 3. MockRoutineRepository Schema

**Files:** `lib/core/mocks/mock_routine_repository.dart` + `mock_routine_payload.dart`

`MockRoutineRepository implements RoutineRepository`:
- `getWeeklyRoutine(): Future<List<WorkoutDay>>` — awaits `latency`, then maps `mockRoutineApiPayload` through `WorkoutDay.fromJson` (same parse path as HTTP → contract parity guaranteed).
- `generateRoutine(String userPreferences): Future<String>` — awaits `latency`, returns `mockGeneratedRoutineApiPayload.description` with `{userPreferences}` substituted (mirrors `RoutineController.Generate` in C#).

**Payload schema** (`mockRoutineApiPayload: List<Map<String,dynamic>>`, mirrors the C# RAG/Ollama API JSON):

```jsonc
[{
  "id": 1, "name": "Chest & Triceps", "dayOfWeek": "Monday",
  "description": "...",
  "model": "llama3",                       // Ollama model tag
  "generatedAt": "2026-08-15T09:30:00Z",   // ISO-8601 UTC
  "sources": ["rag://exercise-library/chest", "rag://nutrition/protein"], // RAG citations
  "exercises": [{
    "id": 1001, "name": "Bench Press", "muscleGroup": "Chest",
    "series": 4,            // C# name; Dart Exercise.fromJson reads series ?? sets
    "reps": "8-12",         // string (supports "60 sec" time-based reps)
    "restSeconds": 90
  }],
  "nutrition": {
    "totalCalories": 2100, "protein": 140, "carbs": 220, "fat": 70,
    "meals": [{
      "id": 101, "name": "Oatmeal with berries",
      "mealType": "breakfast",              // MealType enum: breakfast|lunch|dinner|snack
      "calories": 350, "protein": 12, "carbs": 55, "fat": 8
    }]
  }
}]
```

Seed data: 3 routines (Mon/Wed/Fri — push/pull/legs), 3 exercises each, nutrition block per day; plus 1 `mockGeneratedRoutineApiPayload` object (id 99, `dayOfWeek: "Weekly"`) for the AI-generate flow.

Model mapping (tolerant parse in `routine_models.dart`): `dayOfWeek|weekday` → `weekday`, `name|focus` → `focus`, `series|sets` → `sets`; `nutrition` nullable.

## 4. Verification Plan
- `flutter analyze` clean; `flutter test` (widget test asserts dev config → mocks + dark theme).
- Contract test: `WorkoutDay.fromJson` over every payload entry round-trips (non-null exercises, nutrition, meals).
- Runtime: `flutter run -t lib/main_dev.dart` (mocks) and `--dart-define=USE_MOCK_API=false` override path.
