# NutriExercise Backend — Architecture

This document describes the technical architecture of `backend`, a .NET 8
**Clean Architecture** solution that powers the NutriExercise ecosystem. It
provides a REST API for workout routines (including AI-generated routines via a
local LLM) backed by a cloud PostgreSQL database.

The solution contains four projects: `NutriExercise.Api`,
`NutriExercise.Core`, `NutriExercise.Infrastructure` and
`NutriExercise.Tests`, all targeting `net8.0`.

---

## Directory Tree

```
backend/
├── NutriExercise.sln
│
├── NutriExercise.Api/                          # Presentation / Composition Root
│   ├── NutriExercise.Api.csproj
│   ├── Program.cs                              # DI wiring + middleware pipeline
│   ├── NutriExercise.Api.http                  # HTTP scratchpad
│   ├── appsettings.json                        # Connection string + logging
│   ├── appsettings.Development.json
│   ├── Properties/
│   │   └── launchSettings.json
│   └── Controllers/
│       ├── AiProxyController.cs                # Placeholder (no endpoints yet)
│       └── RoutineController.cs                # Routine CRUD + AI generation
│
├── NutriExercise.Core/                         # Domain layer (no dependencies)
│   ├── NutriExercise.Core.csproj
│   ├── Entities/
│   │   ├── Diet.cs
│   │   ├── Routine.cs
│   │   └── User.cs
│   └── Interfaces/
│       ├── IAiService.cs                       # LLM abstraction
│       ├── IRepository.cs                      # Unused marker interface
│       └── IRoutineRepository.cs               # Routine persistence contract
│
├── NutriExercise.Infrastructure/               # Persistence + external integrations
│   ├── NutriExercise.Infrastructure.csproj
│   ├── Data/
│   │   ├── AppDbContext.cs                     # EF Core DbContext (pgvector)
│   │   └── RoutineRepository.cs                # IRoutineRepository implementation
│   ├── Services/
│   │   └── OllamaAiService.cs                  # Local Ollama LLM integration
│   └── Migrations/
│       ├── 20260808060037_InitialCreate.cs     # Initial schema migration
│       ├── 20260808060037_InitialCreate.Designer.cs
│       └── AppDbContextModelSnapshot.cs        # EF model snapshot
│
└── NutriExercise.Tests/                        # xUnit test project
    ├── NutriExercise.Tests.csproj
    ├── GlobalUsings.cs
    └── EntitySmokeTests.cs                     # Entity default-value smoke tests
```

---

## Clean Architecture Breakdown

The dependency rule flows inward: **Api → Infrastructure → Core**, with the
Api also referencing Core directly. Core never references any other layer and
has **zero package dependencies**, keeping the domain fully isolated.

```
┌──────────────────────────────┐
│   NutriExercise.Api          │  HTTP controllers, DI, configuration
├──────────────────────────────┤
│   NutriExercise.Infrastructure│ EF Core, repositories, Ollama integration
├──────────────────────────────┤
│   NutriExercise.Core         │  Domain entities + interface contracts
└──────────────────────────────┘
```

### NutriExercise.Core — Domain Layer

Pure domain model: entities and abstractions only, no external packages.

- **Entities** — simple POCOs with an integer identity and string properties
  defaulted to `string.Empty`:
  - `User` (Id, Name, Email)
  - `Routine` (Id, Name, DayOfWeek, Description)
  - `Diet` (Id, Name, MealType, Description)
- **Interfaces** — the contracts implemented by Infrastructure:
  - `IAiService.GenerateRoutineAsync(userPreferences, ct)` — LLM abstraction.
  - `IRoutineRepository` — async CRUD for `Routine` (`GetByIdAsync`,
    `GetAllAsync`, `AddAsync`, `UpdateAsync`, `DeleteAsync`), each accepting a
    `CancellationToken`.
  - `IRepository<TEntity>` — an empty generic marker interface (currently
    unused scaffolding).

### NutriExercise.Infrastructure — Persistence & Integrations

- **`AppDbContext`** — EF Core `DbContext` exposing `DbSet<User> Users`,
  `DbSet<Routine> Routines` and `DbSet<Diet> Diets`. In `OnModelCreating` it
  calls `HasPostgresExtension("vector")`, declaring the **pgvector**
  extension on the database. Mapping is convention-based (identity primary
  keys, `text` columns).
- **`RoutineRepository`** — implements `IRoutineRepository` on top of
  `AppDbContext`: `FindAsync` for by-id lookups, `AsNoTracking` for reads,
  and `Add/Update/Remove` plus `SaveChangesAsync` for writes.
- **`OllamaAiService`** — the local LLM integration (see below).
- **`Migrations/`** — the EF Core code-first migration `InitialCreate`,
  generated with the `dotnet ef` CLI.

### NutriExercise.Api — Presentation / Composition Root

- **`Program.cs`** — minimal-hosting composition root that registers
  controllers, Swagger, `AppDbContext` (Npgsql + pgvector), the named
  `"Ollama"` HTTP client, and the scoped services
  (`IAiService → OllamaAiService`, `IRoutineRepository → RoutineRepository`).
  Middleware pipeline: Swagger (Development) → HTTPS redirection →
  `MapControllers`.
- **`RoutineController`** (route `api/routine`) — exposes four endpoints:

  | Method | Route | Description |
  |---|---|---|
  | `POST` | `api/routine/generate` | Generates a routine with the LLM and persists it |
  | `GET` | `api/routine` | Returns all routines |
  | `GET` | `api/routine/{id:int}` | Returns a single routine (404 if absent) |
  | `DELETE` | `api/routine/{id:int}` | Deletes a routine (404 if absent) |

- **`AiProxyController`** (route `api/aiproxy`) — an `[ApiController]` with no
  actions yet; reserved for future AI proxy/streaming endpoints.
- The `GenerateRoutineRequest` DTO (single `UserPreferences` string) is
  declared inline with the controller.

### NutriExercise.Tests

- **Framework:** xUnit 2.4.2 (`Microsoft.NET.Test.Sdk`, `xunit.runner.visualstudio`, `coverlet.collector`).
- **`EntitySmokeTests.cs`** — three `[Fact]` tests asserting that the
  default-constructed entities have `string.Empty` defaults for their string
  properties.

---

## Key Integrations

### Cloud PostgreSQL (EF Core Code-First)

- **Provider:** Npgsql (`Npgsql.EntityFrameworkCore.PostgreSQL` 8.0.11) backed
  by a **Supabase-hosted cloud PostgreSQL** instance, connected through the
  pooled endpoint (`aws-1-us-west-2.pooler.supabase.com:5432`).
- **Connection string** is configured in
  `NutriExercise.Api/appsettings.json` under
  `ConnectionStrings:DefaultConnection`, with `SslMode=Require`, server
  certificate trust enabled and connection pooling enabled.
- **Registration** in `Program.cs`:

  ```csharp
  builder.Services.AddDbContext<AppDbContext>(options =>
      options.UseNpgsql(connStr, o => o.UseVector()));
  ```

- **pgvector** is wired at both the provider option level (`UseVector()`,
  from `pgvector.EntityFrameworkCore` 0.2.2) and the model level
  (`HasPostgresExtension("vector")`), preparing the schema for future vector
  embeddings / semantic search.
- **Migrations:** `InitialCreate` creates the `Diets`, `Routines` and `Users`
  tables using PostgreSQL `IDENTITY` columns, plus the `vector` extension.
  Apply with `dotnet ef database update`.

### Local Ollama LLM Integration — `OllamaAiService`

- Implements `IAiService` and talks to a **local Ollama server** through a
  named `HttpClient` registered as `"Ollama"` with base address
  `http://localhost:11434/` and a 5-minute timeout.
- **`GenerateRoutineAsync`**:
  1. Builds an `OllamaGenerateRequest` `{ model = "llama3", prompt = ..., stream = false }`.
  2. POSTs JSON to the Ollama `api/generate` endpoint.
  3. Ensures success and deserializes `OllamaGenerateResponse`, returning the
     generated text.
- The prompt instructs the model to act as a professional fitness coach and
  produce a structured weekly workout routine from the user's preferences.
- The API then wraps the generated text in a `Routine` entity
  (`Name = "AI Generated Routine"`, `DayOfWeek = "Weekly"`,
  `Description = generatedText`) and persists it through the repository.

---

## Notes & Next Steps

- There is **no separate Application/Use-Case layer** yet; orchestration (AI
  generation + persistence) currently lives in `RoutineController`.
- Only `Routine` has a repository; `User` and `Diet` have DbSets but no
  abstractions or endpoints.
- `OllamaAiService` is hardwired to `http://localhost:11434` and model
  `llama3`; these could be moved to configuration for flexibility.
- The Supabase credentials in `appsettings.json` should be moved to
  environment variables or a secrets manager before production.
- Repository, service, controller and integration tests are not yet covered.
