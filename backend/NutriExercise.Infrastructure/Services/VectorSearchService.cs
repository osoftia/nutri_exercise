using NutriExercise.Core.DTOs;
using NutriExercise.Core.Interfaces;
using Pgvector;

namespace NutriExercise.Infrastructure.Services;

public class VectorSearchService : IVectorSearchService
{
    private const int CandidateLimit = 5;

    private readonly IAiService _aiService;
    private readonly IResearchDocumentRepository _researchDocumentRepository;
    private readonly IRagLogger _ragLogger;

    public VectorSearchService(
        IAiService aiService,
        IResearchDocumentRepository researchDocumentRepository,
        IRagLogger ragLogger)
    {
        ArgumentNullException.ThrowIfNull(aiService);
        ArgumentNullException.ThrowIfNull(researchDocumentRepository);
        ArgumentNullException.ThrowIfNull(ragLogger);

        _aiService = aiService;
        _researchDocumentRepository = researchDocumentRepository;
        _ragLogger = ragLogger;
    }

    public async Task<IReadOnlyList<string>> SearchAsync(
        string query,
        double similarityThreshold,
        CancellationToken cancellationToken = default)
    {
        var result = await SearchWithScoresAsync(
            query,
            similarityThreshold,
            cancellationToken);

        return result.Contexts;
    }

    public async Task<VectorSearchResult> SearchWithScoresAsync(
        string query,
        double similarityThreshold,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(query))
        {
            return EmptyResult();
        }

        var embedding = await _aiService.GenerateEmbeddingAsync(
            query,
            cancellationToken);

        if (embedding.Length == 0)
        {
            return EmptyResult();
        }

        List<Core.Entities.ResearchDocument> documents;

        try
        {
            documents = await _researchDocumentRepository
                .SearchSimilarDocumentsAsync(
                    embedding,
                    CandidateLimit,
                    cancellationToken);
        }
        catch (Exception ex)
        {
            _ragLogger.LogError(
                ex,
                "pgvector similarity search failed. Query={Query}, Dimensions={Dimensions}.",
                query,
                embedding.Length);

            throw;
        }

        var queryVector = new Vector(embedding);

        var matches = documents
            .Where(document => document.Embedding is not null)
            .Select(document => new
            {
                document.Content,
                Score = CosineSimilarity(document.Embedding!, queryVector)
            })
            .Where(match => match.Score >= similarityThreshold)
            .ToList();

        _ragLogger.LogInfo(
            "Vector search complete. Candidates={CandidateCount}, Matches={MatchCount}, Threshold={Threshold}.",
            documents.Count,
            matches.Count,
            similarityThreshold);

        return new VectorSearchResult(
            matches.Select(match => match.Content).ToList(),
            matches.Select(match => match.Score).ToList());
    }

    private static double CosineSimilarity(Vector a, Vector b)
    {
        var left = a.ToArray();
        var right = b.ToArray();

        if (left.Length == 0 || left.Length != right.Length)
        {
            return 0.0;
        }

        double dot = 0.0;
        double leftNorm = 0.0;
        double rightNorm = 0.0;

        for (var index = 0; index < left.Length; index++)
        {
            dot += left[index] * right[index];
            leftNorm += left[index] * left[index];
            rightNorm += right[index] * right[index];
        }

        if (leftNorm == 0.0 || rightNorm == 0.0)
        {
            return 0.0;
        }

        return dot / (Math.Sqrt(leftNorm) * Math.Sqrt(rightNorm));
    }

    private static VectorSearchResult EmptyResult() =>
        new(Array.Empty<string>(), Array.Empty<double>());
}
