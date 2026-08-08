using NutriExercise.Core.Entities;

namespace NutriExercise.Core.Interfaces;

public interface IRoutineRepository
{
    Task<Routine?> GetByIdAsync(int id, CancellationToken cancellationToken = default);

    Task<IEnumerable<Routine>> GetAllAsync(CancellationToken cancellationToken = default);

    Task AddAsync(Routine routine, CancellationToken cancellationToken = default);

    Task UpdateAsync(Routine routine, CancellationToken cancellationToken = default);

    Task DeleteAsync(int id, CancellationToken cancellationToken = default);
}
