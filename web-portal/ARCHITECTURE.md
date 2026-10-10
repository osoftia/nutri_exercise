# NutriExercise Web Portal — Architecture

## Overview

The web portal is an **Angular** application (version 22) built with **standalone components**, **signals** and modern control flow (`@if` / `@for`). The UI follows the **Atomic Design** methodology, organizing components from the smallest reusable pieces to full pages.

## Atomic Design Structure

```
src/app/
├── components/
│   ├── atoms/        # Smallest reusable building blocks
│   │   ├── custom-button/
│   │   ├── form-input/
│   │   └── icon/
│   ├── molecules/    # Combinations of atoms
│   │   ├── board-column/   # Muscle-group column (cdkDropList + card list)
│   │   ├── exercise-card/  # Card with checkbox select + form-input inline edit
│   │   ├── search-bar/
│   │   └── stat-card/
│   ├── organisms/    # Self-contained sections
│   │   ├── admin-sidebar/
│   │   ├── data-table/
│   │   ├── routine-board/  # Trello-style board (/routine-board, cdkDropListGroup)
│   │   └── top-navbar/
│   └── templates/    # Page layouts (future)
├── core/
│   ├── mocks/        # Mock data used when environment.useMocks is true
│   │   ├── mock-diet.data.ts
│   │   ├── mock-interaction.data.ts
│   │   └── mock-routine.data.ts
│   └── services/     # HTTP clients wired to the C# backend
│       ├── auth.ts
│       ├── database.service.ts       # Generic-table explorer (DbTable API)
│       ├── diet.ts
│       ├── exercise-routine.service.ts # Generic exercise catalog CRUD
│       ├── interaction.ts
│       ├── routine.ts
│       └── telemetry.service.ts      # Snapshot API + global logger (only console.* owner)
│   ├── stores/       # Signal stores (mock fallback via mock-*.data.ts)
│   │   └── routine-board.store.ts
│   ├── utils/        # Pure helpers (no CDK/Angular deps)
│   │   ├── exercise.mapper.ts
│   │   └── routine-drag.util.ts
│   └── models/
│       └── routine-board.model.ts
├── pages/            # Route-level components
│   ├── admin-dashboard/dashboard-home/
│   └── interaction-history/
└── app.routes.ts     # Router configuration
```

## RLHF (Reinforcement Learning from Human Feedback) Components

### `InteractionService` (`core/services/interaction.ts`)

Service injected with `HttpClient` that talks to the C# backend:

- `getHistory()` → `GET {apiUrl}/api/interaction/history` — fetches all AI interactions ordered by creation date descending.
- `submitFeedback(id, isCorrect)` → `PUT {apiUrl}/api/interaction/{id}/feedback` — sends the human rating for an interaction.

It mirrors the `useMocks` pattern used by `Diet` and `Routine`, falling back to `mock-interaction.data.ts` during development.

### `InteractionHistory` (`pages/interaction-history/`)

Route-level page (`/history`) that:

- Loads the interaction history on `ngOnInit` using signals (`interactions`, `loading`).
- Renders each interaction as a card showing the creation date, `userPrompt` and the model used.
- Expands to reveal the exact RAG context (`usedContext`) and the generated routine (`generatedRoutine`).
- Lets the user rate the response as **Correct** or **Incorrect** via `onRate()`, which calls `InteractionService.submitFeedback()` and updates local state (buttons are replaced by the chosen rating once set).

## Routine Board (Trello-style drag-and-drop)

Contract: `src/app/features/routine-board.feature` (7 scenarios).

- **Model** (`core/models/routine-board.model.ts`): `MuscleGroup`, `GenericExercise`,
  `RoutineColumn`, `RoutineBoard`, `CreateExercisePayload`, `UpdateExercisePayload`.
- **Utils** (`core/utils/routine-drag.util.ts`, `core/utils/exercise.mapper.ts`):
  dependency-free array helpers with CDK `moveItemInArray`/`transferArrayItem`
  semantics (`reorderColumns`, `moveCardInColumn`, `transferCard`,
  `exercisesForColumn`) plus catalog mappers (`toGenericExercise`,
  `fromWorkoutDay`, `normalizeMuscleGroup`). Covered by
  `routine-drag.util.spec.ts` + `exercise.mapper.spec.ts`.
- **Services** (`core/services/exercise-routine.service.ts`,
  `core/services/database.service.ts`): catalog CRUD against
  `GET/POST {apiUrl}/api/v1/exercises/generic`, `PATCH {apiUrl}/api/v1/exercises/generic/{id}`,
  `POST {apiUrl}/api/v1/exercises/generic/bulk-delete` with `localStorage`
  persistence when `environment.useMocks` is true.
- **Store** (`core/stores/routine-board.store.ts` + `.spec.ts`): signals
  (`columns`, `exercises`, `loading`, `error`, `selectedIds`) with mock fallback
  via `mock-routine.data.ts`; covers load, column reorder, card move/transfer,
  inline rename, bulk delete, custom-exercise create.
- **UI**: `molecules/exercise-card` (checkbox bulk-select, `form-input` inline
  rename, `custom-button` actions), `molecules/board-column` (`cdkDropList` card
  list), `organisms/routine-board` (`/routine-board`, horizontal
  `cdkDropListGroup`, add-custom-exercise form). Sidebar `Routines` links to
  `/routine-board`.

## Logging

`TelemetryService` (`core/services/telemetry.service.ts`) is the **global logger**
(`debug/info/warn/error()` with `[Telemetry:<level>]` prefix, plus `getSnapshot()`
for the analytics API). `error.interceptor.ts` routes HTTP errors through
`telemetry.error()`. `main.ts` bootstrap catch stays as-is. Covered by
`telemetry.service.spec.ts`.

`RagLoggerService` (`core/services/rag-logger.service.ts`) is the **RAG-scoped
logger** and, alongside `TelemetryService`, the only other place allowed to call
`console.*` (`info()` → `console.info` with `[RAG-INFO]:` prefix for successful
queries, ingestion actions and store state changes; `error()` → `console.error`
with `[RAG-ERROR]:` prefix for failed HTTP calls, empty state exceptions and
unexpected server responses). `RagService` traces query/ingest outcomes through
it; `RagIngest` traces form state transitions. Covered by
`rag-logger.service.spec.ts`.

## Routing

Defined in `app.routes.ts`:

| Path              | Component            | Purpose                          |
| ----------------- | -------------------- | -------------------------------- |
| `/admin-dashboard`| `DashboardHome`      | Main dashboard (routines/diet)   |
| `/history`        | `InteractionHistory` | RLHF interaction history review  |
| `/routine-board`  | `RoutineBoard`       | Trello-style exercise routine creator |
| `/analytics`      | `AnalyticsPage`      | Analytics summary (lazy)         |
| `/rag-lab`        | `PromptLab`          | RAG prompt lab (lazy)            |
| `/rag-ingest`     | `RagIngest`          | RAG knowledge ingestion form (lazy, `POST /api/rag/ingest`, test user `Id = 1`) |
| `` (empty)        | → `/history` | Default redirect                 |

The root layout (`app.ts` / `app.html`) renders a top navigation bar with links to **Inicio** and **Historial RLHF**, plus the `<router-outlet />` where routed components are injected.

## Environments

Configuration lives in `src/environments/`:

- `environment.ts` — default (development) values.
- `environment.development.ts` — dev overrides (`apiUrl: http://localhost:5439`).
- `environment.qa.ts` / `environment.prod.ts` — QA and production endpoints.

Each environment exposes `production`, `useMocks` and `apiUrl`, consumed by the core services.
