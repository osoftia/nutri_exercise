using Microsoft.EntityFrameworkCore;
using NutriExercise.Core.Entities;
using NutriExercise.Core.Interfaces;
using NutriExercise.Infrastructure.Data;

namespace NutriExercise.Infrastructure.Data;

public class DailyLogRepository : IDailyLogRepository
{
    private readonly AppDbContext _context;

    public DailyLogRepository(AppDbContext context)
    {
        _context = context;
    }

    public async Task AddAsync(DailyLogRecord record, CancellationToken cancellationToken = default)
    {
        _context.DailyLogRecords.Add(record);
        await _context.SaveChangesAsync(cancellationToken);
    }

    public async Task<DailyLogRecord?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default)
    {
        return await _context.DailyLogRecords.FindAsync(new object[] { id }, cancellationToken);
    }

    public async Task<IEnumerable<DailyLogRecord>> GetAllAsync(CancellationToken cancellationToken = default)
    {
        return await _context.DailyLogRecords.AsNoTracking().ToListAsync(cancellationToken);
    }
}