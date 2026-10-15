using NutriExercise.Core.Entities;

namespace NutriExercise.Core.Interfaces;

public interface IUserRepository
{
    Task<User?> GetByIdAsync(int id, CancellationToken cancellationToken = default);

    Task<User> EnsureSeedUserAsync(CancellationToken cancellationToken = default);
}
