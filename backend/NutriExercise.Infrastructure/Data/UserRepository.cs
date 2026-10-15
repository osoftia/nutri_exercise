using Microsoft.EntityFrameworkCore;
using NutriExercise.Core.Configuration;
using NutriExercise.Core.Entities;
using NutriExercise.Core.Interfaces;

namespace NutriExercise.Infrastructure.Data;

public class UserRepository : IUserRepository
{
    private readonly AppDbContext _context;
    private readonly IRagLogger _ragLogger;

    public UserRepository(AppDbContext context, IRagLogger ragLogger)
    {
        ArgumentNullException.ThrowIfNull(context);
        ArgumentNullException.ThrowIfNull(ragLogger);

        _context = context;
        _ragLogger = ragLogger;
    }

    public async Task<User?> GetByIdAsync(int id, CancellationToken cancellationToken = default)
    {
        return await _context.Users
            .AsNoTracking()
            .FirstOrDefaultAsync(user => user.Id == id, cancellationToken);
    }

    public async Task<User> EnsureSeedUserAsync(CancellationToken cancellationToken = default)
    {
        var existing = await _context.Users
            .FirstOrDefaultAsync(user => user.Id == DefaultUser.Id, cancellationToken);

        if (existing is not null)
        {
            return existing;
        }

        var seedUser = new User
        {
            Id = DefaultUser.Id,
            Name = DefaultUser.Name,
            Email = DefaultUser.Email
        };

        _context.Users.Add(seedUser);
        await _context.SaveChangesAsync(cancellationToken);

        _ragLogger.LogInfo(
            "Database seeding complete. Default user ensured (Id={UserId}, Email={Email}).",
            seedUser.Id,
            seedUser.Email);

        return seedUser;
    }
}
