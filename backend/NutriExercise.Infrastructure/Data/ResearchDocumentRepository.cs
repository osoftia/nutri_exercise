using Microsoft.EntityFrameworkCore;
using NutriExercise.Core.Entities;
using NutriExercise.Core.Interfaces;
using Pgvector.EntityFrameworkCore;

namespace NutriExercise.Infrastructure.Data;

public class ResearchDocumentRepository : IResearchDocumentRepository
{
    private readonly AppDbContext _context;

    public ResearchDocumentRepository(AppDbContext context)
    {
        _context = context;
    }

    public async Task AddDocumentAsync(ResearchDocument document, CancellationToken cancellationToken = default)
    {
        _context.ResearchDocuments.Add(document);
        await _context.SaveChangesAsync(cancellationToken);
    }

    public async Task<bool> HasDocumentsAsync(CancellationToken cancellationToken = default)
    {
        return await _context.ResearchDocuments.AnyAsync(cancellationToken);
    }

    public async Task<List<ResearchDocument>> SearchSimilarDocumentsAsync(float[] queryVector, int limit = 2, CancellationToken cancellationToken = default)
    {
        var vector = new Pgvector.Vector(queryVector);
        return await _context.ResearchDocuments
            .Where(d => d.Embedding != null)
            .OrderBy(d => d.Embedding!.CosineDistance(vector))
            .Take(limit)
            .ToListAsync(cancellationToken);
    }
}
