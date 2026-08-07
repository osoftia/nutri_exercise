# PHASE 2 — C# Backend Core (RESTful API + Business Logic)

> **Author:** [Qwen] (Development & QA Lead)
> **Status:** Draft — pending approval
> **Depends on:** `docs/phase-1/02-sdd-contracts.md` (contracts), `01-github-management.md` (structure/CI)
> **Scope:** Structural implementation of the C# .NET backend: solution layout, domain model, business algorithms (BMR/TDEE/macro, workout generation), EF Core + PostgreSQL, REST controllers, DI, exception pipeline, and offline-sync server logic.

---

## 1. Solution Layout (Clean Architecture, SOLID)

```text
backend/
├── NutriExercise.sln
├── Directory.Build.props            # shared analyzers, warnings-as-errors, LangVersion
├── src/
│   ├── NutriExercise.Domain/           # entities, value objects, enums, domain errors
│   ├── NutriExercise.Application/      # DTOs, use cases, ports (interfaces), algorithms
│   ├── NutriExercise.Infrastructure/   # EF Core DbContext, Postgres, repositories, sync engine
│   └── NutriExercise.Api/              # controllers, middleware, DI composition root, Program.cs
└── tests/
    ├── NutriExercise.Domain.Tests/
    ├── NutriExercise.Application.Tests/
    └── NutriExercise.Api.Tests/        # WebApplicationFactory integration
```

### Dependency Rule

```text
Api -> Application -> Domain
Api -> Infrastructure -> Domain
Application -> Domain (ports defined here)
```

- **Domain:** zero dependencies.
- **Application:** depends only on Domain (ports = `I…Repository`, `IUnitOfWork`).
- **Infrastructure:** implements Application ports; EF Core / Npgsql.
- **Api:** composition root only; no business logic in controllers.

### Namespace conventions

`NutriExercise.Domain.Entities.*`, `NutriExercise.Application.Features.*` (feature-folder per SDD contract), `NutriExercise.Infrastructure.Persistence.*`.

---

## 2. Domain Model

### 2.1 Core Enums (Domain.Shared)

```csharp
namespace NutriExercise.Domain.Shared;

public enum Gender { Male, Female, Other }
public enum Goal { LoseFat, BuildMuscle, Maintain }
public enum ActivityLevel { Sedentary, Light, Moderate, High }
public enum TrainingScope { Day, Week }
public enum MuscleGroupId { Chest, Back, Shoulders, Biceps, Triceps, Forearms,
                            Core, Glutes, Quads, Hamstrings, Calves, Traps, Lats }
public enum Equipment { Bodyweight, Dumbbells, Barbell, Kettlebell, Cable, Machine }
public enum SyncOperation { Create, Update, Delete }
public enum SyncStatus { Applied, Conflict, Rejected }
```

### 2.2 Entities (extract of contract §5.1)

```csharp
public sealed class Profile : Entity<Guid>
{
    public Guid UserId { get; private set; }
    public Gender Gender { get; private set; }
    public int AgeYears { get; private set; }
    public double HeightCm { get; private set; }
    public double WeightKg { get; private set; }
    public Goal Goal { get; private set; }
    public ActivityLevel ActivityLevel { get; private set; }
    public int TrainingDaysPerWeek { get; private set; }
    public IReadOnlyList<Equipment> Equipment { get; private set; }
    public IReadOnlyList<string> DietaryRestrictions { get; private set; }
    public double Bmr { get; private set; }
    public double Tdee { get; private set; }
    public DateTimeOffset UpdatedAtUtc { get; private set; }

    public static Profile Create(ProfileDraft draft) { /* enforces invariants, computes BMR/TDEE via calculator */ }
    public void Recalculate(double bmr, double tdee) { Bmr = bmr; Tdee = tdee; UpdatedAtUtc = DateTimeOffset.UtcNow; }
}

public sealed class Exercise : Entity<Guid>
{
    public string Name { get; private set; }
    public MuscleGroupId PrimaryMuscle { get; private set; }
    public IReadOnlyList<MuscleGroupId> SecondaryMuscles { get; private set; }
    public Equipment Equipment { get; private set; }
    public string Difficulty { get; private set; }
    public string InstructionsMd { get; private set; }
    public string SvgPathId { get; private set; }
    public bool IsActive { get; private set; }
}

public sealed class WorkoutPlan : Entity<Guid>       // aggregates plan_days -> plan_exercises
public sealed class Schedule : Entity<Guid>
public sealed class SyncInbox : Entity<Guid>          // idempotency key = ClientChangeId
```

- Value object: `MacroSplit { ProteinG, CarbsG, FatG }` with validation (sum of kcal ≈ target).

---

## 3. Business Logic Algorithms (Application)

### 3.1 BMR — Mifflin-St Jeor (`NutritionalCalculator`)

```csharp
namespace NutriExercise.Application.Algorithms;

public static class NutritionalCalculator
{
    public static double CalculateBmr(Gender gender, int ageYears, double heightCm, double weightKg)
    {
        var baseBmr = (10 * weightKg) + (6.25 * heightCm) - (5 * ageYears);
        return gender switch
        {
            Gender.Male   => baseBmr + 5,
            Gender.Female => baseBmr - 161,
            Gender.Other  => baseBmr,
            _             => throw new ArgumentOutOfRangeException(nameof(gender))
        };
    }

    public static double CalculateTdee(double bmr, ActivityLevel level) => level switch
    {
        ActivityLevel.Sedentary => bmr * 1.2,
        ActivityLevel.Light     => bmr * 1.375,
        ActivityLevel.Moderate  => bmr * 1.55,
        ActivityLevel.High      => bmr * 1.725,
        _ => throw new ArgumentOutOfRangeException(nameof(level))
    };
}
```

### 3.2 Macro Split (`MacroCalculator`)

```csharp
public static MacroSplit CalculateMacros(double tdee, Goal goal)
{
    // kcal surplus/deficit by goal
    var target = goal switch
    {
        Goal.LoseFat     => tdee - 500,   // ~0.45 kg/week
        Goal.BuildMuscle => tdee + 300,
        Goal.Maintain    => tdee,
        _                => throw new ArgumentOutOfRangeException(nameof(goal))
    };

    var proteinPerKg = goal switch
    {
        Goal.LoseFat     => 2.0,
        Goal.BuildMuscle => 2.0,
        Goal.Maintain    => 1.6,
        _                => 1.6
    };
    var fatG   = (0.25 * target) / 9;
    var proteinG = proteinPerKg * /* user's lean-ish weight = current weight */ 0.8;
    var proteinKcal = proteinG * 4;
    var carbsG = (target - proteinKcal - (fatG * 9)) / 4;

    return new MacroSplit(
        ProteinG: Math.Round(proteinG),
        CarbsG:   Math.Round(carbsG),
        FatG:     Math.Round(fatG),
        TargetKcal: (int)Math.Round(target));
}
```

### 3.3 Workout Generator (`WorkoutGenerator`)

Selection algorithm:

```csharp
public sealed class WorkoutGenerator
{
    // port to the exercise catalog
    private readonly IExerciseRepository _exercises;

    public WorkoutPlan Generate(GenerateWorkoutCommand cmd)
    {
        var targets = cmd.TargetMuscles.Any() ? cmd.TargetMuscles : MuscleRotation.Next(cmd.TrainingDaysPerWeek);
        var pool = _exercises.GetByMuscles(targets, cmd.ExcludedExercises, cmd.Equipment);
        var day = DayComposer.Compose(targets, pool, cmd.DurationMinutes);
        return new WorkoutPlan(cmd.ProfileId, day);
    }
}

internal static class MuscleRotation
{
    // returns a muscle-group day split for N training days/week,
    // e.g. 4 days -> [Chest, Back, Legs, Shoulders+Arms]
}

internal static class DayComposer
{
    // greedy packing: pick 4-6 exercises hitting all target muscles,
    // allocate sets/reps by difficulty, cap by durationMinutes,
    // avoid repeating the same primary muscle back-to-back.
}
```

### 3.4 Sync Engine (server side)

```csharp
public sealed class SyncService
{
    private readonly ISyncInboxRepository _inbox;

    public async Task<PushResult> PushAsync(PushRequest request, CancellationToken ct)
    {
        var results = new List<ChangeResult>();
        foreach (var change in request.Changes)
        {
            // idempotency: unique ClientChangeId -> skip replays (Return Previous Applied)
            if (await _inbox.ExistsAsync(change.ClientChangeId, ct)) { results.Add(AlreadyApplied(change)); continue; }

            try
            {
                await ApplyAsync(change, ct);                       // INSERT/UPDATE/DELETE by entity type
                await _inbox.InsertAsync(new SyncInbox(change));    // record after successful apply
                results.Add(new ChangeResult(change.EntityId, SyncStatus.Applied, null));
            }
            catch (ConflictException) { results.Add(new ChangeResult(change.EntityId, SyncStatus.Conflict, "conflict")); }
            catch (ValidationException ex) { results.Add(new ChangeResult(change.EntityId, SyncStatus.Rejected, ex.Message)); }
        }
        return new PushResult(results);
    }
}
```

- Conflict detection: compare `updatedAtUtc` in payload vs server row → if server newer **and** payload entity is not fully mergeable, return `Conflict` (client shows review UI, LWW policy).

---

## 4. Infrastructure (EF Core + PostgreSQL)

### 4.1 DbContext

```csharp
public sealed class NutriDbContext : DbContext
{
    public DbSet<Profile> Profiles => Set<Profile>();
    public DbSet<Exercise> Exercises => Set<Exercise>();
    public DbSet<WorkoutPlan> WorkoutPlans => Set<WorkoutPlan>();
    public DbSet<Schedule> Schedules => Set<Schedule>();
    public DbSet<SyncInbox> SyncInbox => Set<SyncInbox>();

    protected override void OnConfiguring(DbContextOptionsBuilder b) =>
        b.UseNpgsql(connection, o => o.UseNodaTime())      // TIMESTAMPTZ via NodaTime
         .UseSnakeCaseNamingConvention();                  // id, created_at_utc

    protected override void OnModelCreating(ModelBuilder mb)
    {
        mb.Entity<Profile>().ToTable("profiles").HasKey(p => p.Id);
        mb.Entity<Exercise>().Property(e => e.SecondaryMuscles)
          .HasColumnType("jsonb").HasConversion(new JsonListConverter<MuscleGroupId>());
        // enums stored as varchar; soft delete filter for exercises: IsActive == true
    }
}
```

### 4.2 Migrations & Startup

- Migrations committed in `NutriExercise.Infrastructure/Migrations`, applied in CI/dev via `dotnet ef database update` (dev) and containerized init job (prod).
- Connection string via env: `DATABASE_URL=Host=…;Port=5432;Database=nutri;Username=…;Password=…`.
- **No secrets in source** — `.env`/appsettings overrides git-ignored.

---

## 5. API Layer

### 5.1 Program.cs (composition root)

```csharp
var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers().AddFluentValidationAutoValidation();
builder.Services.AddValidatorsFromAssembly(typeof(OnboardingProfileValidator).Assembly);

builder.Services.AddScoped<IProfileRepository, EfProfileRepository>();
builder.Services.AddScoped<IExerciseRepository, EfExerciseRepository>();
builder.Services.AddScoped<IScheduleRepository, EfScheduleRepository>();
builder.Services.AddScoped<ISyncInboxRepository, EfSyncInboxRepository>();
builder.Services.AddScoped<IUnitOfWork, EfUnitOfWork>();
builder.Services.AddScoped<WorkoutGenerator>();
builder.Services.AddScoped<SyncService>();
builder.Services.AddDbContext<NutriDbContext>(/* from env */);

builder.Services.AddProblemDetails();
builder.Services.AddOpenApi();                            // minimal OpenAPI in dev

var app = builder.Build();
app.UseExceptionHandler();                                // central pipeline
app.UseMiddleware<ValidationExceptionMiddleware>();
app.MapControllers();
app.Run();
```

### 5.2 Controllers (thin, use cases only)

```csharp
[ApiController, Route("api/v1/onboarding")]
public sealed class OnboardingController : ControllerBase
{
    [HttpPost("profile")]
    public async Task<ActionResult<ProfileResponse>> Submit(
        [FromBody] OnboardingProfileRequest request, CancellationToken ct)
    {
        var response = await _handler.HandleAsync(request, ct);
        return Created($"/api/v1/onboarding/profile/{response.ProfileId}", response);
    }
}

[ApiController, Route("api/v1/workouts")]
public sealed class WorkoutsController : ControllerBase
{
    [HttpPost("generate")]
    public async Task<ActionResult<WorkoutPlanResponse>> Generate(
        [FromBody] GenerateWorkoutRequest request, CancellationToken ct) => Ok(await _handler.HandleAsync(request, ct));
}

[ApiController, Route("api/v1/schedules")]
public sealed class SchedulesController : ControllerBase { /* GET list, POST create, DELETE */ }

[ApiController, Route("api/v1/sync")]
public sealed class SyncController : ControllerBase
{
    [HttpPost("push")] public async Task<ActionResult<PushResponse>> Push(PushRequest r, CancellationToken ct) => Ok(await _sync.PushAsync(r, ct));
    [HttpPost("pull")] public async Task<ActionResult<PullResponse>> Pull(PullRequest r, CancellationToken ct) => Ok(await _sync.PullAsync(r, ct));
}
```

### 5.3 Validation (FluentValidation)

```csharp
public sealed class OnboardingProfileValidator : AbstractValidator<OnboardingProfileRequest>
{
    public OnboardingProfileValidator()
    {
        RuleFor(x => x.AgeYears).InclusiveBetween(13, 100);
        RuleFor(x => x.HeightCm).InclusiveBetween(100, 250);
        RuleFor(x => x.WeightKg).InclusiveBetween(30, 300);
        RuleFor(x => x.TrainingDaysPerWeek).InclusiveBetween(1, 7);
        RuleFor(x => x.TrainingDaysPerWeek).Equal(0)
            .WithMessage("…") /* via cross-field validator for goal=maintain */;
        RuleFor(x => x.Equipment).NotEmpty();
    }
}
```

### 5.4 Exception Pipeline

| Exception | HTTP | Body |
| --- | --- | --- |
| `NotFoundException` | 404 | `{ "errors": ["NOT_FOUND"] }` |
| `ValidationException` | 400 | `{ "errors": ["VALIDATION_ERROR"], "details": {…} }` |
| `ConflictException` | 409 | `{ "errors": ["CONFLICT"] }` |
| `DomainException` | 422 | business rule violation |
| unhandled | 500 | `{ "errors": ["INTERNAL"] }` (no stack trace leak) |

Middleware maps exceptions via `ProblemDetails`; request logging with `requestId`.

---

## 6. .NET Version & Tooling

- .NET 8 (LTS), C# 12, `Nullable` + `ImplicitUsings` enabled.
- Analyzers: `Microsoft.CodeAnalysis.NetAnalyzers`, warnings-as-errors in CI.
- EF Core 8 + `Npgsql.EntityFrameworkCore.PostgreSQL` 8.x.
- Formatting gate: `dotnet format --verify-no-changes`.
- Deploy concept: Dockerfile → container registry → Azure App Service / ECS placeholder (Phase 1 §7.2).

---

## 7. Test Strategy Summary

| Concern | Framework | Location |
| --- | --- | --- |
| Algorithm correctness (BMR/TDEE/macro/generator) | xUnit | `Application.Tests` |
| Entity invariants | xUnit | `Domain.Tests` |
| Controller contracts + validation + error codes | xUnit + `WebApplicationFactory` | `Api.Tests` |
| Sync idempotency + conflict resolution | xUnit (InMemory/Testcontainers-Postgres) | `Application.Tests` / `Api.Tests` |

Detailed cases in `docs/phase-2/02-backend-qa.md`.

---

## 8. Approved Decisions & Open Decisions

**Approved (PHASE 2 gate):**
1. Timestamps: **NodaTime** (`UseNodaTime()` on Npgsql, TIMESTAMPTZ).
2. Sync integration tests: **Testcontainers.PostgreSql** in a dedicated CI job.

**Open:**
1. Auth: JWT bearer enforced now vs. stubbed for local dev (Phase 1 open item).
