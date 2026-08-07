# PHASE 2 — Backend QA (xUnit Test Suite)

> **Author:** [Qwen] (Development & QA Lead)
> **Status:** Draft — pending approval
> **Depends on:** `docs/phase-2/01-backend-core.md`
> **Scope:** Naming conventions, project structure, and representative xUnit tests for business algorithms, domain invariants, controller contracts, validation, and offline-sync idempotency.

---

## 1. Test Project Layout

```text
tests/
├── NutriExercise.Domain.Tests/          # entities, value objects, enum behavior
│   └── MacroSplitTests.cs
├── NutriExercise.Application.Tests/     # algorithms + use cases (no DB)
│   ├── NutritionalCalculatorTests.cs
│   ├── MacroCalculatorTests.cs
│   ├── WorkoutGeneratorTests.cs
│   └── SyncServiceTests.cs
└── NutriExercise.Api.Tests/             # integration via WebApplicationFactory
    ├── OnboardingEndpointTests.cs
    ├── WorkoutsEndpointTests.cs
    └── SyncEndpointTests.cs
```

Dependencies: `xunit`, `xunit.runner.visualstudio`, `Microsoft.NET.Test.Sdk`, `FluentAssertions`, `Moq` (unit), `Microsoft.AspNetCore.Mvc.Testing` (API), `Testcontainers.PostgreSql` (integration).

---

## 2. Naming & Structure Conventions

- **Class:** `[UnitUnderTest]Tests` — e.g. `WorkoutGeneratorTests`.
- **Method:** `[Method]_[Scenario]_[Expected]` — e.g. `CalculateBmr_Male_AddsFive`.
- **AAA layout:** Arrange / Act / Assert, one logical assertion per test (or a `[Theory]` with multiple cases).
- **Categories:** `[Trait("Category", "Algorithm")]`, `[Trait("Category", "Contract")]`, `[Trait("Category", "Sync")]`, `[Trait("Category", "Validation")]`.
- Every algorithm must have a **pure unit test**; endpoints covered by **contract tests**; sync engine covered by **integration tests** against a real Postgres (Testcontainers) to guarantee idempotency.

---

## 3. Unit Tests — Algorithms

### 3.1 `NutritionalCalculatorTests`

```csharp
public class NutritionalCalculatorTests
{
    [Theory]
    [InlineData(Gender.Male, 32, 178, 82, 1780.5)]      // golden values from domain calc
    [InlineData(Gender.Female, 28, 165, 60, 1337.5)]
    public void CalculateBmr_ReturnsExpectedBmr(Gender g, int age, double h, double w, double expected)
    {
        var bmr = NutritionalCalculator.CalculateBmr(g, age, h, w);
        bmr.Should().BeApproximately(expected, 0.5);
    }

    [Theory]
    [InlineData(ActivityLevel.Sedentary, 1.2)]
    [InlineData(ActivityLevel.High, 1.725)]
    public void CalculateTdee_AppliesCorrectMultiplier(ActivityLevel level, double multiplier)
    {
        var tdee = NutritionalCalculator.CalculateTdee(2000, level);
        tdee.Should().BeApproximately(2000 * multiplier, 0.01);
    }

    [Fact]
    public void CalculateTdee_UnknownLevel_Throws() =>
        FluentActions.Invoking(() => NutritionalCalculator.CalculateTdee(2000, (ActivityLevel)99))
                     .Should().Throw<ArgumentOutOfRangeException>();
}
```

### 3.2 `MacroCalculatorTests`

```csharp
public class MacroCalculatorTests
{
    [Fact]
    public void CalculateMacros_LoseFat_CreatesDeficitAndHigherProtein()
    {
        var split = MacroCalculator.CalculateMacros(2500, Goal.LoseFat);

        split.TargetKcal.Should().Be(2000);                       // 2500 - 500
        (split.ProteinG * 4).Should().BeGreaterThan(split.CarbsG / 2); // protein-dominant
    }

    [Theory]
    [InlineData(Goal.BuildMuscle, 300)]
    [InlineData(Goal.Maintain, 0)]
    public void CalculateMacros_KcalDelta_MatchesGoal(Goal goal, int delta)
    {
        var split = MacroCalculator.CalculateMacros(2500, goal);
        split.TargetKcal.Should().Be(2500 + delta);
    }

    [Fact]
    public void CalculateMacros_MacroKcalSum_EqualsTargetWithinTolerance()
    {
        var split = MacroCalculator.CalculateMacros(2200, Goal.Maintain);
        var kcal = (split.ProteinG * 4) + (split.CarbsG * 4) + (split.FatG * 9);
        Math.Abs(kcal - split.TargetKcal).Should().BeLessThan(30); // rounding tolerance
    }
}
```

### 3.3 `WorkoutGeneratorTests`

```csharp
public class WorkoutGeneratorTests
{
    private readonly Mock<IExerciseRepository> _repo = new();

    [Fact]
    public void Generate_TargetMuscles_CoversAllTargets()
    {
        _repo.Setup(r => r.GetByMuscles(It.IsAny<IReadOnlyList<MuscleGroupId>>(), It.IsAny<IReadOnlyList<Guid>>(), It.IsAny<Equipment?>()))
             .Returns(new[] { ExerciseFixtures.ChestPress, ExerciseFixtures.CableFly, ExerciseFixtures.ChestDip });
        var gen = new WorkoutGenerator(_repo.Object);

        var plan = gen.Generate(new GenerateWorkoutCommand(Guid.NewGuid(), new[] { MuscleGroupId.Chest }, []));

        plan.Days.Single().Exercises.Should().OnlyContain(e => e.Muscles.Contains(MuscleGroupId.Chest));
    }

    [Fact]
    public void Generate_DurationCap_DoesNotExceedRequestedMinutes()
    {
        // greedy composer must drop overflow exercises; assert sum(rest + est. sets) <= 45 min
    }

    [Fact]
    public void Generate_NoTargetMuscles_UsesRotation()
    {
        // empty TargetMuscles -> MuscleRotation day for TrainingDaysPerWeek
    }
}
```

### 3.4 `SyncServiceTests` (integration, Testcontainers Postgres)

```csharp
[Collection("Postgres")]
public class SyncServiceTests
{
    [Fact]
    public async Task Push_SameClientChangeId_AppliedOnlyOnce()
    {
        await _sync.PushAsync(ChangeOf(Entity: "completedWorkout", clientChangeId: "C-1"), ct);
        await _sync.PushAsync(ChangeOf(Entity: "completedWorkout", clientChangeId: "C-1"), ct);

        var count = await _inbox.CountAsync();
        count.Should().Be(1);                       // idempotency: replay skipped
    }

    [Fact]
    public async Task Push_ServerRowNewer_ReturnsConflict()
    {
        // seed server row with updatedAtUtc later than payload
        var result = await _sync.PushAsync(ChangeOf(updatedAtUtc: older), ct);
        result.Results.Single().Status.Should().Be(SyncStatus.Conflict);
    }

    [Fact]
    public async Task Pull_AfterPush_ReturnsNewerServerChanges()
    {
        // cursor advance check: pull(sinceUtc) returns only newer entities
    }
}
```

---

## 4. API Contract Tests (`WebApplicationFactory`)

### 4.1 `OnboardingEndpointTests`

```csharp
public class OnboardingEndpointTests : IClassFixture<NutriApiFactory>
{
    private readonly HttpClient _client = new NutriApiFactory().CreateClient();

    [Fact]
    public async Task Submit_ValidPayload_Returns201WithProfileAndMacros()
    {
        var response = await _client.PostAsJsonAsync("/api/v1/onboarding/profile", Payload.Valid);

        response.StatusCode.Should().Be(HttpStatusCode.Created);
        var body = await response.Content.ReadFromJsonAsync<ProfileResponse>();
        body!.Bmr.Should().BeGreaterThan(0);
        body.MacroSplit.Should().NotBeNull();
    }

    [Fact]
    public async Task Submit_InvalidWeight_Returns400ValidationError()
    {
        var response = await _client.PostAsJsonAsync("/api/v1/onboarding/profile", Payload.With(weightKg: 1));

        response.StatusCode.Should().Be(HttpStatusCode.BadRequest);
        (await response.Content.ReadAsStringAsync()).Should().Contain("VALIDATION_ERROR");
    }

    [Fact]
    public async Task Submit_MissingEquipment_Returns422() { /* DomainException path */ }
}
```

### 4.2 `WorkoutsEndpointTests`

```csharp
[Fact]
public async Task Generate_ValidRequest_Returns200WithPlanDays()
{
    var response = await _client.PostAsJsonAsync("/api/v1/workouts/generate", Payload.Valid);

    response.StatusCode.Should().Be(HttpStatusCode.OK);
    var body = await response.Content.ReadFromJsonAsync<WorkoutPlanResponse>();
    body!.Days.Should().NotBeEmpty();
    body.Days[0].Exercises.Should().OnlyContain(e => e.Sets is > 0 and <= 6);
}

[Fact]
public async Task Generate_UnknownProfile_Returns404NotFound() { /* NotFoundException -> 404 */ }
```

### 4.3 `SchedulesEndpointTests`

- `POST /api/v1/schedules` valid → 201; duplicate weekday+time → 409 Conflict.
- `GET /api/v1/schedules` returns only the caller's schedules (auth header stub).
- `DELETE` existing → 204; missing → 404.

### 4.4 Error-Contract Tests (all endpoints)

- Unknown route → 404 with envelope.
- Malformed JSON → 400 with `VALIDATION_ERROR`.
- Internal error (stubbed exception) → 500 without stack trace in body.

---

## 5. CI Enforcement

`ci-backend.yml` runs, on every PR touching `backend/**`:

```bash
dotnet restore NutriExercise.sln
dotnet build NutriExercise.sln -c Release --no-restore
dotnet format NutriExercise.sln --verify-no-changes --no-restore
dotnet test NutriExercise.sln -c Release --no-build \
  --filter "Category!=Contract"          # fast unit + algorithm suites
# contract/integration suite gated to a later stage (needs Testcontainers)
```

Coverage gate (informational for now): ≥ 80% on `Application` assembly via `coverlet`.

---

## 6. Open Decisions

1. Move sync integration tests to a separate slower CI job (with Postgres service container)?
2. Enable coverage threshold as blocking (≥80% on Application) from Phase 2 or Phase 3?
