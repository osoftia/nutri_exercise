using NutriExercise.Core.Entities;

namespace NutriExercise.Core.Interfaces;

public interface IClinicalMenuRepository
{
    Task<DailySymptomLog> AddSymptomLogAsync(
        DailySymptomLog log,
        CancellationToken cancellationToken = default);

    Task<ClinicalMenuPlan> AddPlanAsync(
        ClinicalMenuPlan plan,
        CancellationToken cancellationToken = default);
}
