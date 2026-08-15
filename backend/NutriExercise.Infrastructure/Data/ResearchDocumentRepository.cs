using NutriExercise.Core.Entities;
using NutriExercise.Core.Interfaces;

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
}
