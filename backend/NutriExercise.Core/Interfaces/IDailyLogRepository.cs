using NutriExercise.Core.Entities;

namespace NutriExercise.Core.Interfaces;

public interface IDailyLogRepository
{
    Task AddAsync(DailyLogRecord record, CancellationToken cancellationToken = default);

    Task<DailyLogRecord?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);

    Task<IEnumerable<DailyLogRecord>> GetAllAsync(CancellationToken cancellationToken = default);

    Task<bool> DeleteAsync(Guid id, CancellationToken cancellationToken = default);
}