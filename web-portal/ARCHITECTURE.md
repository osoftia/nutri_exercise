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
│   │   ├── search-bar/
│   │   └── stat-card/
│   ├── organisms/    # Self-contained sections
│   │   ├── admin-sidebar/
│   │   ├── data-table/
│   │   └── top-navbar/
│   └── templates/    # Page layouts (future)
├── core/
│   ├── mocks/        # Mock data used when environment.useMocks is true
│   │   ├── mock-diet.data.ts
│   │   ├── mock-interaction.data.ts
│   │   └── mock-routine.data.ts
│   └── services/     # HTTP clients wired to the C# backend
│       ├── auth.ts
│       ├── diet.ts
│       ├── interaction.ts
│       └── routine.ts
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

## Routing

Defined in `app.routes.ts`:

| Path              | Component            | Purpose                          |
| ----------------- | -------------------- | -------------------------------- |
| `/admin-dashboard`| `DashboardHome`      | Main dashboard (routines/diet)   |
| `/history`        | `InteractionHistory` | RLHF interaction history review  |
| `` (empty)        | → `/admin-dashboard` | Default redirect                 |

The root layout (`app.ts` / `app.html`) renders a top navigation bar with links to **Inicio** and **Historial RLHF**, plus the `<router-outlet />` where routed components are injected.

## Environments

Configuration lives in `src/environments/`:

- `environment.ts` — default (development) values.
- `environment.development.ts` — dev overrides (`apiUrl: http://localhost:5039`).
- `environment.qa.ts` / `environment.prod.ts` — QA and production endpoints.

Each environment exposes `production`, `useMocks` and `apiUrl`, consumed by the core services.
