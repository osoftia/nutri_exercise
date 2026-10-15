using NutriExercise.Core.Entities;
using NutriExercise.Core.Interfaces;

namespace NutriExercise.Infrastructure.Data;

public class ClinicalMenuRepository : IClinicalMenuRepository
{
    private readonly AppDbContext _context;

    public ClinicalMenuRepository(AppDbContext context)
    {
        ArgumentNullException.ThrowIfNull(context);

        _context = context;
    }

    public async Task<DailySymptomLog> AddSymptomLogAsync(
        DailySymptomLog log,
        CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(log);

        _context.DailySymptomLogs.Add(log);
        await _context.SaveChangesAsync(cancellationToken);

        return log;
    }

    public async Task<ClinicalMenuPlan> AddPlanAsync(
        ClinicalMenuPlan plan,
        CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(plan);

        _context.ClinicalMenuPlans.Add(plan);
        await _context.SaveChangesAsync(cancellationToken);

        return plan;
    }
}
