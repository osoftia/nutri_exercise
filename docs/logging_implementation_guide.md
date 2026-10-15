# Logging Implementation Guide — File-Based Serilog + HTTP Middleware

> Scope: `NutriExercise.Api` and `NutriExercise.Infrastructure`
> Goal: file-first observability to debug mobile (Flutter) → API → Ollama connectivity and the current `500 Internal Server Error`.

## 1. Why file-based logging (and not the database)

The `ErrorLogs` table is still part of the schema, but it is **no longer wired into the
Serilog pipeline**. Writing logs through EF Core/PostgreSQL is a poor fit for the current
failure mode:

- A database write adds a network round-trip and can fail for the *same* reason the API is
  failing (connection string / Supabase / VPN). File logs always work as long as the
  process can write to disk.
- Database writes are synchronous sinks. During a burst of 500s they become a bottleneck.
- Connection-level problems happen *before* the ORM is usable, so DB logging would hide them.

The file sinks run in-process, never throw into the request path, and can be tailed live.

## 2. Serilog configuration

`NutriExercise.Api/Program.cs` builds the logger at startup:

```csharp
const string PlainTextTemplate =
    "[{Timestamp:yyyy-MM-dd HH:mm:ss.fff} {Level:u3}] {Message:lj}{NewLine}{Exception}";

Log.Logger = new LoggerConfiguration()
    .MinimumLevel.Information()
    .MinimumLevel.Override("Microsoft.AspNetCore", LogEventLevel.Warning)
    .Enrich.FromLogContext()
    .WriteTo.Console(outputTemplate: PlainTextTemplate)
    .WriteTo.File(
        path: "Logs/nutriexercise-.log",
        rollingInterval: RollingInterval.Day,
        retainedFileCountLimit: 30,
        shared: true,
        outputTemplate: PlainTextTemplate)
    .WriteTo.File(
        new JsonFormatter(renderMessage: true),
        path: "Logs/nutriexercise-.json",
        rollingInterval: RollingInterval.Day,
        retainedFileCountLimit: 30,
        shared: true)
    .CreateLogger();
```

| Sink | Path | Purpose |
|---|---|---|
| Console | stdout | Live local debugging / `dotnet run` |
| Plain text | `Logs/nutriexercise-YYYYMMDD.log` | Fast `grep`/`tail` while developing |
| JSON | `Logs/nutriexercise-YYYYMMDD.json` | Structured events for future aggregation (Seq/Loki/ELK) |

Key properties:

- **Daily rolling** (`RollingInterval.Day`), **30 files retained**, `shared: true` so the file
  can be tailed while the API runs.
- The plain-text template renders the full `Exception` (stack trace) after the message.
- `MinimumLevel.Override("Microsoft.AspNetCore", Warning)` removes framework request noise;
  our custom `[HTTP-*]` events are not affected.
- The logger is also registered in DI as `Serilog.ILogger`, so middleware/services can inject it.

### RAG prefixes are preserved

`RagLogger` keeps emitting `[RAG-INFO]:` / `[RAG-ERROR]:` through `ILogger<RagLogger>`. Because
the file sinks use `{Message:lj}` (literal message), the prefixes are written verbatim in both
the `.log` and `.json` files:

```
[2026-10-09 10:12:44.531 INF] [RAG-INFO]: Vector inserted. DocumentId=…, UserId=1, BodyZone=…
```

## 3. HTTP request/response middleware

`NutriExercise.Api/Middleware/HttpLoggingMiddleware.cs` logs the full transaction. It is
registered **inside** the global exception middleware so it observes thrown exceptions before
`GlobalExceptionMiddleware` converts them to a `500`:

```csharp
app.UseMiddleware<GlobalExceptionMiddleware>();
app.UseMiddleware<HttpLoggingMiddleware>();
```

What it captures:

| Event tag | When | Fields |
|---|---|---|
| `[HTTP-REQUEST]` | before the pipeline runs | method, path, query, client IP, headers, body |
| `[HTTP-RESPONSE]` | after the pipeline succeeds | method, path, status code, elapsed ms, headers, body |
| `[HTTP-ERROR]` | when the pipeline throws | method, path, client IP, elapsed ms, exception + stack trace |

Safety/robustness notes:

- Request body is read with `EnableBuffering()` and reset to position `0`, so model binding
  still works.
- Response body is buffered in memory, then copied back to the real stream.
- Bodies are truncated at 4096 chars (`MaxBodyLength`).
- `Authorization`, `Cookie` and `Set-Cookie` headers are written as `[REDACTED]`.
- The error path **rethrows**, so `GlobalExceptionMiddleware` still returns
  `500 {"error":"An unexpected error occurred."}`.

## 4. Ollama failure tracing

`NutriExercise.Infrastructure/Services/OllamaAiModelService.cs` now injects
`ILogger<OllamaAiModelService>` and logs both non-success responses and transport failures:

```
[OLLAMA-ERROR] Model llama3 returned 500 from http://localhost:11434/api/generate. Response: …
[OLLAMA-ERROR] Failed to reach Ollama at http://localhost:11434/api/generate for model llama3
<full stack trace>
```

Transport failures (`HttpRequestException`, `TaskCanceledException`, `JsonException`) are logged
with the exception object and rethrown, preserving the stack trace all the way to the file sink.

## 5. Debugging the current 500 Internal Server Error

1. Reproduce the failing call from the Flutter app (Android emulator reaches the host via
   `10.0.2.2`, iOS simulator via `localhost`). Watch the log live:

   ```bash
   cd backend
   tail -f NutriExercise.Api/Logs/nutriexercise-$(date +%Y%m%d).log
   ```

2. Find the failing transaction:

   ```bash
   grep -n "\[HTTP-ERROR\]" NutriExercise.Api/Logs/nutriexercise-*.log
   ```

   The `[HTTP-REQUEST]` line immediately above the error tells you the **exact method, path,
   client IP, headers and body** the mobile client sent. This confirms/denies DTO mismatches
   (e.g. wrong JSON casing, missing `query`).

3. Match the `[HTTP-ERROR]` exception to the module:

   ```bash
   grep -n "\[OLLAMA-ERROR\]\|\[RAG-ERROR\]" NutriExercise.Api/Logs/nutriexercise-*.log
   ```

4. Common causes seen in this codebase:

   | Log signature | Root cause | Fix |
   |---|---|---|
   | `[OLLAMA-ERROR] Failed to reach Ollama … HttpRequestException` | Ollama not running / wrong port | `ollama serve`; verify `http://localhost:11434` |
   | `[OLLAMA-ERROR] Model llama3 returned 404` | model not pulled | `ollama pull llama3` |
   | `[HTTP-ERROR] … Npgsql.NpgsqlException` | PostgreSQL/Supabase unreachable | check `ConnectionStrings:DefaultConnection`, VPN, `docker start backend-db-1` |
   | `[HTTP-ERROR] … relation "…" does not exist` | pending migration | `dotnet ef database update` |
   | `[HTTP-ERROR] … ` on `/api/AiProxy/*` with no `[OLLAMA-ERROR]` | request failed before/during model binding | inspect the `[HTTP-REQUEST]` body |

5. For structured search use the JSON file:

   ```bash
   grep '"Level":"Error"' NutriExercise.Api/Logs/nutriexercise-*.json
   ```

## 6. Automated coverage (BDD)

`NutriExercise.Specs/Features/HttpLogging.feature` locks in the behaviour:

- inbound request (IP, header, body) is logged under `[HTTP-REQUEST]`;
- outgoing response logs the status code under `[HTTP-RESPONSE]`;
- an unhandled exception is logged with a stack trace under `[HTTP-ERROR]` and rethrown.

Run just this feature:

```bash
dotnet test NutriExercise.Specs --filter "FullyQualifiedName~HTTPRequestAndResponseFileLogging"
```

## 7. Operational notes

- Log directory `NutriExercise.Api/Logs/` is created automatically; ensure the process has
  write permission in production.
- 30-day retention is enforced per rolling series (`.log` and `.json` independently).
- To move to centralized aggregation later, add a sink (Seq/Loki) without touching the
  application code — the structured JSON already carries all fields.
