using NutriExercise.Core.Interfaces;
using Pgvector;
using Pgvector.EntityFrameworkCore;

namespace NutriExercise.Infrastructure.Services;

public class VectorSearchService : IVectorSearchService
{
    private const int CandidateLimit = 5;

    private readonly IAiService _aiService;
    private readonly IResearchDocumentRepository _researchDocumentRepository;

    public VectorSearchService(
        IAiService aiService,
        IResearchDocumentRepository researchDocumentRepository)
    {
        ArgumentNullException.ThrowIfNull(aiService);
        ArgumentNullException.ThrowIfNull(researchDocumentRepository);

        _aiService = aiService;
        _researchDocumentRepository = researchDocumentRepository;
    }

    public async Task<IReadOnlyList<string>> SearchAsync(
        string query,
        double similarityThreshold,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(query))
        {
            return Array.Empty<string>();
        }

        var embedding = await _aiService.GenerateEmbeddingAsync(
            query,
            cancellationToken);

        if (embedding.Length == 0)
        {
            return Array.Empty<string>();
        }

        var documents = await _researchDocumentRepository
            .SearchSimilarDocumentsAsync(
                embedding,
                CandidateLimit,
                cancellationToken);

        var queryVector = new Vector(embedding);

        return documents
            .Where(document => document.Embedding is not null)
            .Where(document =>
                1.0 - document.Embedding!.CosineDistance(queryVector)
                    >= similarityThreshold)
            .Select(document => document.Content)
            .ToList();
    }
}
