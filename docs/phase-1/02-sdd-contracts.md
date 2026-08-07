# PHASE 1 — SDD Contracts

> **Author:** [Qwen] (Development & QA Lead)
> **Status:** Draft — pending approval
> **Scope:** API contracts, offline-sync strategy, and database schemas (SQLite mobile + centralized SQL backend) for the NutriExercise platform.

---

## 1. System Context

```text
                    +--------------------------+
                    |     C# .NET 8 Backend     |
                    | NutriExercise.Api (REST)  |
                    |    SQL Database (central) |
                    +-------------+-------------+
                                  ^
                    HTTPS / JSON  |
        +-------------------------+-------------------------+
        |                                                  |
+-------+--------+                                 +-------+--------+
|  Angular Web   |                                 |  Flutter Mobile  |
|  (PWA/online)  |                                 |  (offline-first) |
+----------------+                                 +-----------------+
                                                   |  SQLite (local) |
                                                   |  AI Interceptor |
                                                   +-----------------+
```

- **Web (Angular):** online-first; interacts with the API directly.
- **Mobile (Flutter):** offline-first; local SQLite is the source of truth for reads, writes queued for sync.

---

## 2. Versioning & Conventions

- Base URL: `/api/v1`.
- All payloads are JSON (UTF-8). Dates are ISO-8601 UTC.
- IDs: server-generated `Guid` (backend) / `UUID` (mobile) to enable offline creation without collisions.
- Auth: JWT Bearer (web) + device-scoped API key for anonymous offline sync (planned).
- Standard envelope (consistent across endpoints):

```json
{
  "data": { },
  "meta": { "requestId": "…", "timestamp": "…" },
  "errors": [ ]
}
```

- Error codes: `NOT_FOUND`, `VALIDATION_ERROR`, `CONFLICT`, `UNAUTHORIZED`, `NETWORK_REQUIRED`.

---

## 3. API Contract

### 3.1 Onboarding

**`POST /api/v1/onboarding/profile`** — submit initial user metrics.

Request:

```json
{
  "userId": "uuid",
  "profile": {
    "gender": "male|female|other",
    "ageYears": 32,
    "heightCm": 178,
    "weightKg": 82,
    "goal": "LOSE_FAT|BUILD_MUSCLE|MAINTAIN",
    "activityLevel": "SEDENTARY|LIGHT|MODERATE|HIGH",
    "trainingDaysPerWeek": 4,
    "equipment": ["DUMBBELLS", "BODYWEIGHT"],
    "dietaryRestrictions": ["VEGETARIAN", "NO_LACTOSE"],
    "timezone": "America/Bogota"
  }
}
```

Response `201`:

```json
{
  "data": {
    "profileId": "uuid",
    "bmr": 1754.5,
    "tdee": 2412.0,
    "macroSplit": { "proteinG": 180, "carbsG": 280, "fatG": 70 },
    "generatedAtUtc": "2026-08-07T18:00:00Z"
  }
}
```

Derived algorithms (business logic, Phase 2): Mifflin-St Jeor for BMR → TDEE via activity multiplier → macro split by goal.

### 3.2 Workout Generation

**`POST /api/v1/workouts/generate`** — generate daily/weekly routine.

Request:

```json
{
  "profileId": "uuid",
  "scope": "DAY|WEEK",
  "targetMuscles": ["CHEST", "BACK", "QUADS"],
  "excludedExercises": ["uuid", "uuid"],
  "durationMinutes": 45
}
```

Response `200`:

```json
{
  "data": {
    "planId": "uuid",
    "days": [
      {
        "dayIndex": 1,
        "title": "Push Day",
        "exercises": [
          {
            "exerciseId": "uuid",
            "name": "Incline Dumbbell Press",
            "muscles": ["CHEST"],
            "sets": 4,
            "reps": "8-12",
            "restSeconds": 90,
            "equipment": "DUMBBELLS"
          }
        ]
      }
    ]
  }
}
```

### 3.3 Exercise & Muscle Catalog

- **`GET /api/v1/exercises?muscle=CHEST&equipment=DUMBBELLS`** → paginated exercise list `{ items, page, pageSize, total }`.
- **`GET /api/v1/exercises/{id}`** → exercise detail (name, muscles, equipment, difficulty, instructions, vectors).
- **`GET /api/v1/muscles`** → muscle group catalog incl. **body-map vector metadata**:

```json
{
  "data": {
    "muscles": [
      {
        "id": "CHEST",
        "label": "Chest",
        "svgPathId": "chest",
        "primaryColor": "#3B82F6",
        "isViewable": ["FRONT", "BACK"]
      }
    ]
  }
}
```

### 3.4 Nutrition

**`POST /api/v1/nutrition/menu/generate`**

Request:

```json
{
  "profileId": "uuid",
  "calorieTargetKcal": 2200,
  "macroTarget": { "proteinG": 180, "carbsG": 240, "fatG": 60 },
  "dietaryRestrictions": ["VEGETARIAN"]
}
```

Response `200` → weekly meal plan with per-meal items (name, kcal, macros, ingredients, recipe steps).

### 3.5 Scheduling & Notifications

- **`GET|POST /api/v1/schedules`** — read/create user schedule.
- **`DELETE /api/v1/schedules/{id}`** — remove a schedule.
- Schedule payload:

```json
{
  "id": "uuid",
  "profileId": "uuid",
  "weekday": "MONDAY",
  "timeLocal": "18:30",
  "activityType": "WORKOUT|MEAL_REMINDER",
  "refId": "planId or menuId",
  "notificationEnabled": true,
  "createdAtUtc": "…"
}
```

Mobile stores schedules locally; notifications scheduled by `flutter_local_notifications` at sync time.

### 3.6 Offline Sync

- **`POST /api/v1/sync/push`** — batch upsert of locally created/modified entities.

Request:

```json
{
  "deviceId": "uuid",
  "changes": [
    {
      "entity": "completedWorkout|schedule|logEntry",
      "operation": "CREATE|UPDATE|DELETE",
      "entityId": "uuid",
      "payload": { },
      "changedAtUtc": "…"
    }
  ]
}
```

Response `200`:

```json
{
  "data": {
    "results": [
      { "entityId": "uuid", "status": "APPLIED|CONFLICT|REJECTED", "serverEntityId": "uuid", "error": null }
    ],
    "serverChanges": [ "…" ]
  }
}
```

- **`POST /api/v1/sync/pull?sinceUtc=…`** — incremental pull (see §4).

### 3.7 AI Assistant

- **`POST /api/v1/ai/query`**

Request:

```json
{
  "sessionId": "uuid",
  "message": "Suggest a chest workout using dumbbells",
  "context": { "profileId": "uuid", "language": "es" }
}
```

Response `200`:

```json
{
  "data": { "reply": "…", "intent": "WORKOUT_SUGGESTION", "suggestions": ["uuid"] }
}
```

**Mobile interceptor behavior:** if offline, the request is NOT sent; the client returns a friendly `NETWORK_REQUIRED` response to the UI (see §5). For a better UX it may answer from a curated local FAQ model first.

---

## 4. Offline-Sync Strategy

### 4.1 Principles

1. **Mobile = source of truth for writes** while offline (optimistic updates).
2. **Reads prefer local cache**; refresh from server via incremental pull.
3. **Sync is idempotent** — every change carries `clientChangeId` so replays are safe.
4. **Conflict resolution:** server-side `updatedAtUtc` comparison → `last-write-wins` by default; if both sides changed the same field on the same entity, mark `CONFLICT` and surface to user.

### 4.2 Sync Queue (SQLite)

| Column         | Type     | Notes                              |
| -------------- | -------- | ---------------------------------- |
| `id`           | INTEGER PK | local rowid                       |
| `clientChangeId` | TEXT UNIQUE | UUID, idempotency key             |
| `entity`       | TEXT     | e.g. `completedWorkout`            |
| `operation`    | TEXT     | CREATE / UPDATE / DELETE           |
| `entityId`     | TEXT     | local UUID of the entity           |
| `payload`      | TEXT     | JSON body                          |
| `status`       | TEXT     | PENDING / SYNCING / APPLIED / CONFLICT / REJECTED |
| `attempts`     | INT      | retry counter (max 5)              |
| `changedAtUtc` | TEXT     | ISO-8601                           |

### 4.3 Sync Flow

```text
[App launch / connectivity regained]
   -> POST /sync/push (flush PENDING queue)
        -> apply results, resolve CONFLICT/REJECTED locally
   -> POST /sync/pull?sinceUtc=<cursor>
        -> apply serverChanges to local cache
        -> advance cursor
```

- Connectivity monitored via `connectivity_plus`.
- Background retry with exponential backoff; user-visible status badge (offline/queued).
- **Conflict surfacing:** conflicts stored in `sync_conflicts` table and shown in a "Review changes" screen.

### 4.4 AI Interceptor Logic

```text
onSubmit(AI message):
    if connectivity.isOnline:
        return api.ai.query(message)
    else:
        // local fallback: curated FAQ keywords -> canned answer
        if localIntentMatches(message):
            return localCannedReply
        // otherwise prevent crash + guide user
        return { status: NETWORK_REQUIRED, reply: "Connect to the internet to use the AI assistant." }
```

- Wraps the HTTP call in a try/catch; **no unhandled exceptions**.
- Optionally stores the query in `ai_offline_queue` for later resend.

---

## 5. Database Schemas

### 5.1 Centralized PostgreSQL (Backend — EF Core / Npgsql)

**users**

| Column | Type | Notes |
| --- | --- | --- |
| `id` | UUID PK | |
| `email` | VARCHAR(320) UNIQUE | |
| `displayName` | VARCHAR(100) | |
| `authProvider` | VARCHAR(20) | email/google/apple |
| `createdAtUtc` | TIMESTAMPTZ | |

**profiles**

| Column | Type | Notes |
| --- | --- | --- |
| `id` | UUID PK | |
| `userId` | FK → users | |
| `gender` | VARCHAR(10) | |
| `ageYears` | INT | |
| `heightCm` | NUMERIC(5,1) | |
| `weightKg` | NUMERIC(5,1) | |
| `goal` | VARCHAR(20) | |
| `activityLevel` | VARCHAR(20) | |
| `trainingDaysPerWeek` | INT | |
| `equipment` | TEXT | JSON array |
| `dietaryRestrictions` | TEXT | JSON array |
| `bmr` | NUMERIC(7,2) | |
| `tdee` | NUMERIC(7,2) | |
| `updatedAtUtc` | TIMESTAMPTZ | conflict resolution |

**muscle_groups**

| Column | Type |
| --- | --- |
| `id` | VARCHAR(20) PK (`CHEST`, …) |
| `label` | VARCHAR(50) |
| `svgPathId` | VARCHAR(50) |
| `view` | VARCHAR(10) |
| `primaryColorHex` | VARCHAR(9) |

**exercises**

| Column | Type | Notes |
| --- | --- | --- |
| `id` | UUID PK | |
| `name` | VARCHAR(120) | |
| `primaryMuscleId` | VARCHAR(20) FK | |
| `secondaryMuscles` | TEXT | JSON array |
| `equipment` | VARCHAR(50) | |
| `difficulty` | VARCHAR(20) | |
| `instructionsMd` | TEXT | |
| `svgPathId` | VARCHAR(50) | for illustration |
| `isActive` | BOOLEAN | soft delete |

**workout_plans / plan_days / plan_exercises**

```text
workout_plans (id, profileId, name, scope, createdAtUtc)
plan_days    (id, planId, dayIndex, title)
plan_exercises(id, dayId, exerciseId, sets, reps, restSeconds, orderIndex)
```

**meal_plans / meals / meal_items**

```text
meal_plans(id, profileId, kcalTarget, macroTargetJson, createdAtUtc)
meals    (id, mealPlanId, dayIndex, mealType, title, totalKcal, macrosJson)
meal_items(id, mealId, name, ingredientJson, recipeStepsMd)
```

**schedules**

| Column | Type |
| --- | --- |
| `id` | UUID PK |
| `profileId` | FK |
| `weekday` | VARCHAR(10) |
| `timeLocal` | VARCHAR(5) |
| `activityType` | VARCHAR(20) |
| `refId` | UUID |
| `notificationEnabled` | BOOLEAN |
| `updatedAtUtc` | TIMESTAMPTZ |

**sync_inbox**

| Column | Type | Notes |
| --- | --- | --- |
| `id` | UUID PK | |
| `deviceId` | UUID | |
| `clientChangeId` | VARCHAR(64) UNIQUE | idempotency |
| `entity` | VARCHAR(30) | |
| `operation` | VARCHAR(10) | |
| `entityId` | UUID | |
| `payloadJson` | TEXT | |
| `receivedAtUtc` | TIMESTAMPTZ | |

### 5.2 Local SQLite (Mobile — `drift`/`sqflite`)

Mirrors a read-optimized subset + offline extensions:

```text
profiles          (id, gender, ageYears, heightCm, weightKg, goal, activityLevel, trainingDaysPerWeek, equipmentJson, dietaryJson, bmr, tdee, updatedAtUtc)
muscle_groups     (id, label, svgPathId, view, primaryColorHex)
exercises         (id, name, primaryMuscleId, secondaryMusclesJson, equipment, difficulty, instructionsMd, svgPathId, isActive)
workout_plans     (id, profileId, name, scope, createdAtUtc, isLocalDirty)
plan_days         (id, planId, dayIndex, title, isLocalDirty)
plan_exercises    (id, dayId, exerciseId, sets, reps, restSeconds, orderIndex, isLocalDirty)
completed_workouts(id, planId, performedAtUtc, durationMinutes, rating, isLocalDirty)
meal_plans        (id, profileId, kcalTarget, macroTargetJson, createdAtUtc)
meals             (id, mealPlanId, dayIndex, mealType, title, totalKcal, macrosJson)
meal_items        (id, mealId, name, ingredientJson, recipeStepsMd)
schedules         (id, profileId, weekday, timeLocal, activityType, refId, notificationEnabled, updatedAtUtc, isLocalDirty)
sync_queue        (§4.2 schema)
sync_conflicts    (id, clientChangeId, entity, entityId, localJson, serverJson, resolved)
ai_offline_queue  (id, sessionId, message, createdAtUtc, retryCount)
meta              (key, value)   // sync cursor, deviceId, profileId
```

- Foreign keys + `ON DELETE CASCADE` for plan→days→exercises.
- `isLocalDirty` drives the sync queue flush.

---

## 6. Test Strategy Summary (contract-level)

| Layer | Framework | Focus |
| --- | --- | --- |
| Domain/Core | xUnit | macro/BMR calc, workout generation algorithm |
| API | xUnit + WebApplicationFactory | endpoint contract, validation, status codes |
| Mobile repos | `flutter_test` + `drift` in-memory | CRUD, sync queue, conflict resolution |
| Sync | contract/integration | idempotency, conflict resolution, cursor advance |

---

## 7. Approved Decisions & Open Decisions

**Approved (PHASE 1 gate):**
1. DBMS: **PostgreSQL** (EF Core / Npgsql provider) — JSON arrays may map to `JSONB`.
2. Conflict policy: **Last-write-wins** by default + field-level **conflict review UI** (sync_conflicts surfaced to user).

**Open:**
1. JWT vs. device API key for anonymous mobile sync.
