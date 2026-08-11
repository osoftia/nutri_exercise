# NutriExercise

A multi-project ecosystem for fitness and nutrition management, consisting of a
Flutter mobile application, a .NET 8 Clean Architecture backend with local AI
integration, and an Angular web portal.

## Projects

| Directory | Description |
|---|---|
| [`mobile_app/`](mobile_app/ARCHITECTURE.md) | Flutter mobile application with an interactive muscle map, weekly routines, meal plans, Offline-First SQLite persistence, AI connectivity guard and local notifications. |
| [`backend/`](backend/ARCHITECTURE.md) | .NET 8 Clean Architecture REST API (NutriExercise.Api / Core / Infrastructure / Tests) backed by cloud PostgreSQL (EF Core Code-First, pgvector) with a local Ollama LLM service for AI-generated routines. |
| [`web-portal/`](web-portal/) | Angular web portal. |
| [`design-system/`](design-system/) | Design tokens shared across the ecosystem. |
| [`docs/`](docs/) | Specification and phase documentation. |

## Detailed Architecture

- **Mobile application:** see [`mobile_app/ARCHITECTURE.md`](mobile_app/ARCHITECTURE.md)
- **Backend API:** see [`backend/ARCHITECTURE.md`](backend/ARCHITECTURE.md)

## Ecosystem Overview

```
┌─────────────────────────────┐     ┌──────────────────────────────────────┐
│  mobile_app (Flutter)       │     │  backend (.NET 8 Clean Architecture) │
│  · Dashboard + muscle map   │────▶│  · REST API (controllers)            │
│  · Offline-First SQLite     │ HTTP│  · EF Core + PostgreSQL (pgvector)   │
│  · Local notifications      │     │  · OllamaAiService (local LLM)       │
│  · AI connectivity guard    │     └──────────────────────────────────────┘
└─────────────────────────────┘
```

The Flutter app selects its data source at startup (mocks, local SQLite, or the
backend HTTP API). The backend exposes routine CRUD and an AI generation
endpoint that calls a local Ollama server and persists the result in cloud
PostgreSQL.
