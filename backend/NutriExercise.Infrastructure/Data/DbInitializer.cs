using Microsoft.EntityFrameworkCore;
using NutriExercise.Core.Interfaces;

namespace NutriExercise.Infrastructure.Data;

public class DbInitializer
{
    private readonly AppDbContext _context;
    private readonly IUserRepository _userRepository;
    private readonly BaselineKnowledgeSeeder _baselineKnowledgeSeeder;
    private readonly IRagLogger _ragLogger;

    public DbInitializer(
        AppDbContext context,
        IUserRepository userRepository,
        BaselineKnowledgeSeeder baselineKnowledgeSeeder,
        IRagLogger ragLogger)
    {
        ArgumentNullException.ThrowIfNull(context);
        ArgumentNullException.ThrowIfNull(userRepository);
        ArgumentNullException.ThrowIfNull(baselineKnowledgeSeeder);
        ArgumentNullException.ThrowIfNull(ragLogger);

        _context = context;
        _userRepository = userRepository;
        _baselineKnowledgeSeeder = baselineKnowledgeSeeder;
        _ragLogger = ragLogger;
    }

    public async Task InitializeAsync(CancellationToken cancellationToken = default)
    {
        try
        {
            await EnsureDatabaseAsync(cancellationToken);
            await _userRepository.EnsureSeedUserAsync(cancellationToken);
        }
        catch (Exception ex)
        {
            _ragLogger.LogError(
                ex,
                "Database initialization failed. Verify PostgreSQL connectivity and the pgvector extension.");

            throw;
        }

        await TrySeedBaselineVectorsAsync(cancellationToken);

        _ragLogger.LogInfo("Database initialization finished. Migrations and baseline seed are ready.");
    }

    private async Task EnsureDatabaseAsync(CancellationToken cancellationToken)
    {
        var canConnect = await _context.Database.CanConnectAsync(cancellationToken);

        _ragLogger.LogInfo(
            "Database connectivity check. CanConnect={CanConnect}, Provider={Provider}.",
            canConnect,
            _context.Database.ProviderName ?? "unknown");

        if (!_context.Database.IsRelational())
        {
            await _context.Database.EnsureCreatedAsync(cancellationToken);
            _ragLogger.LogInfo("EnsureCreated executed for non-relational provider.");
            return;
        }

        var definedMigrations = _context.Database.GetMigrations().ToList();

        if (definedMigrations.Count == 0)
        {
            await _context.Database.EnsureCreatedAsync(cancellationToken);
            _ragLogger.LogInfo("No migrations defined. EnsureCreated executed.");
            return;
        }

        var pendingMigrations = (await _context.Database
            .GetPendingMigrationsAsync(cancellationToken))
            .ToList();

        if (pendingMigrations.Count == 0)
        {
            _ragLogger.LogInfo("No pending migrations. Database schema is up to date.");
            return;
        }

        _ragLogger.LogInfo(
            "Applying {Count} pending migration(s): {Migrations}.",
            pendingMigrations.Count,
            string.Join(", ", pendingMigrations));

        await _context.Database.MigrateAsync(cancellationToken);

        _ragLogger.LogInfo(
            "Migrations applied successfully. Count={Count}.",
            pendingMigrations.Count);
    }

    private async Task TrySeedBaselineVectorsAsync(CancellationToken cancellationToken)
    {
        try
        {
            await _baselineKnowledgeSeeder.SeedAsync(cancellationToken);
        }
        catch (Exception ex)
        {
            _ragLogger.LogError(
                ex,
                "Baseline vector seeding failed. The API will start without seed knowledge; retry via POST /api/knowledge/seed.");
        }
    }
}
