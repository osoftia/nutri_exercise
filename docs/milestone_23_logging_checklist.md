# Deployment Checklist — NutriExercise Backend (.NET 8)

## Prerequisites

- [ ] .NET 8 SDK installed (`dotnet --version` → `8.x`)
- [ ] PostgreSQL 14+ reachable with the `vector` extension enabled
- [ ] Ollama running locally on `http://localhost:11434` (models: `llama3`, `nomic-embed-text`)
- [ ] `dotnet-ef` global tool installed: `dotnet tool install --global dotnet-ef`

## 1. Configuration

- [ ] Set the `DefaultConnection` connection string in `appsettings.json` (or via env var `ConnectionStrings__DefaultConnection`)
- [ ] Confirm the PostgreSQL host is resolvable and reachable from the deployment environment
- [ ] (Optional) Set `ASPNETCORE_ENVIRONMENT=Production` for production runs

## 2. Restore & Build

```bash
cd backend
dotnet restore
dotnet build --configuration Release
```

## 3. Database Migrations

```bash
dotnet ef database update \
  --project NutriExercise.Infrastructure \
  --startup-project NutriExercise.Api
```

> Applies all pending migrations (InitialCreate, AddRagAndRlTables, AddRlContextAndFeedback, AddDailyLogAndRlTraceTables, AddErrorLogTable).

## 4. Run the API

```bash
dotnet run --project NutriExercise.Api --configuration Release
```

- Swagger UI: `http://localhost:5039/swagger`
- Health check: `GET /swagger` or any controller endpoint

## 5. Logging (Serilog)

- Console + flat JSON file: `Logs/combined.log` (auto-created)
- Error/fatal logs are persisted to the `ErrorLogs` table in PostgreSQL via `ErrorLogSink`
- Global exception middleware returns `500 {"error":"An unexpected error occurred."}` and logs the exception

## 6. Code Quality Gates

- `.editorconfig` enforces strict metrics (CA1502 complexity ≤ 10 via `CodeMetricsConfig.txt`, camelCase naming, maintainability analyzers)
- Run tests: `dotnet test`

## 7. CI/CD (GitHub Actions)

- `.github/workflows/backend-ci.yml` runs restore → build → tests on push/PR to `main` (paths: `backend/**`)
- On `main`, publishes production artifact `backend-production-build`

## Troubleshooting

| Symptom | Cause / Fix |
| --- | --- |
| `ENOTFOUND tenant/user postgres...` | PostgreSQL host not resolvable; check connection string / network / VPN |
| `Failed to determine the https port for redirect` | HTTPS redirection skipped in Development; configure `HttpsPort` or Kestrel endpoint for production |
| Ollama calls fail | Confirm Ollama is running and model names match (`llama3`, `nomic-embed-text`) |