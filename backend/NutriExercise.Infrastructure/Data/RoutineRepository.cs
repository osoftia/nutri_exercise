using Microsoft.EntityFrameworkCore;
using NutriExercise.Core.Entities;
using NutriExercise.Core.Interfaces;
using NutriExercise.Infrastructure.Data;

namespace NutriExercise.Infrastructure.Data;

public class RoutineRepository : IRoutineRepository
{
    private readonly AppDbContext _context;

    public RoutineRepository(AppDbContext context)
    {
        _context = context;
    }

    public async Task<Routine?> GetByIdAsync(int id, CancellationToken cancellationToken = default)
    {
        return await _context.Routines.FindAsync(new object[] { id }, cancellationToken);
    }

    public async Task<IEnumerable<Routine>> GetAllAsync(CancellationToken cancellationToken = default)
    {
        return await _context.Routines.AsNoTracking().ToListAsync(cancellationToken);
    }

    public async Task AddAsync(Routine routine, CancellationToken cancellationToken = default)
    {
        _context.Routines.Add(routine);
        await _context.SaveChangesAsync(cancellationToken);
    }

    public async Task UpdateAsync(Routine routine, CancellationToken cancellationToken = default)
    {
        _context.Routines.Update(routine);
        await _context.SaveChangesAsync(cancellationToken);
    }

    public async Task DeleteAsync(int id, CancellationToken cancellationToken = default)
    {
        var routine = await _context.Routines.FindAsync(new object[] { id }, cancellationToken);
        if (routine is not null)
        {
            _context.Routines.Remove(routine);
            await _context.SaveChangesAsync(cancellationToken);
        }
    }
}
