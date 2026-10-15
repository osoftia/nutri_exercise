using System.Text.Json;
using NutriExercise.Core.DTOs;
using NutriExercise.Core.Entities;
using NutriExercise.Core.Interfaces;

namespace NutriExercise.Infrastructure.Data;

public class ClinicalMenuStore
{
    private readonly IClinicalMenuRepository _repository;
    private readonly IRagLogger _ragLogger;

    public ClinicalMenuStore(
        IClinicalMenuRepository repository,
        IRagLogger ragLogger)
    {
        ArgumentNullException.ThrowIfNull(repository);
        ArgumentNullException.ThrowIfNull(ragLogger);

        _repository = repository;
        _ragLogger = ragLogger;
    }

    public async Task<DailySymptomLog> SaveSymptomLogAsync(
        ClinicalMenuRequest request,
        IReadOnlyList<string> conditions,
        int userId,
        CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(request);

        var log = new DailySymptomLog
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            Symptoms = request.Symptoms ?? string.Empty,
            ActiveConditions = string.Join(", ", conditions),
            CreatedAt = DateTime.UtcNow
        };

        await _repository.AddSymptomLogAsync(log, cancellationToken);

        _ragLogger.LogInfo(
            "Symptom log persisted. LogId={LogId}, UserId={UserId}, Conditions={Conditions}.",
            log.Id,
            userId,
            log.ActiveConditions);

        return log;
    }

    public async Task<ClinicalMenuPlan> SavePlanAsync(
        ClinicalMenuRequest request,
        int userId,
        ClinicalMenuContent menu,
        string modelUsed,
        CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(request);
        ArgumentNullException.ThrowIfNull(menu);

        var plan = new ClinicalMenuPlan
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            Condition = request.Condition,
            MenuJson = JsonSerializer.Serialize(menu),
            ModelUsed = modelUsed,
            CreatedAt = DateTime.UtcNow
        };

        await _repository.AddPlanAsync(plan, cancellationToken);

        _ragLogger.LogInfo(
            "Clinical menu persisted. PlanId={PlanId}, UserId={UserId}, Meals={MealCount}, Exercises={ExerciseCount}.",
            plan.Id,
            userId,
            menu.Meals.Count,
            menu.Exercises.Count);

        return plan;
    }
}
