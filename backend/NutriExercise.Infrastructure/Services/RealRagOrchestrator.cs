using System.Diagnostics;
using NutriExercise.Core.DTOs;
using NutriExercise.Core.Entities;
using NutriExercise.Core.Interfaces;
using Pgvector;

namespace NutriExercise.Infrastructure.Services;

public class RealRagOrchestrator : IRagOrchestrator
{
    private const string IngestSource = "Manual Ingestion";

    private readonly IVectorSearchService _vectorSearchService;
    private readonly IAiModelService _aiModelService;
    private readonly IAiService _aiService;
    private readonly IResearchDocumentRepository _documentRepository;
    private readonly IRagLogger _ragLogger;

    public RealRagOrchestrator(
        IVectorSearchService vectorSearchService,
        IAiModelService aiModelService,
        IAiService aiService,
        IResearchDocumentRepository documentRepository,
        IRagLogger ragLogger)
    {
        ArgumentNullException.ThrowIfNull(vectorSearchService);
        ArgumentNullException.ThrowIfNull(aiModelService);
        ArgumentNullException.ThrowIfNull(aiService);
        ArgumentNullException.ThrowIfNull(documentRepository);
        ArgumentNullException.ThrowIfNull(ragLogger);

        _vectorSearchService = vectorSearchService;
        _aiModelService = aiModelService;
        _aiService = aiService;
        _documentRepository = documentRepository;
        _ragLogger = ragLogger;
    }

    public async Task<RagResponse> ExecuteQueryAsync(
        RagRequest request,
        CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(request);

        var stopwatch = Stopwatch.StartNew();

        try
        {
            var searchResult = await _vectorSearchService.SearchWithScoresAsync(
                request.Query,
                request.SimilarityThreshold,
                cancellationToken);

            var generatedText = await _aiModelService.GenerateAsync(
                request.SystemPrompt,
                request.Query,
                searchResult.Contexts,
                request.Temperature,
                cancellationToken);

            stopwatch.Stop();

            _ragLogger.LogInfo(
                "Model throughput. Characters={CharacterCount}, Contexts={ContextCount}, LatencyMs={LatencyMs}.",
                generatedText.Length,
                searchResult.Contexts.Count,
                stopwatch.ElapsedMilliseconds);

            return new RagResponse(
                generatedText,
                searchResult.Contexts.ToList(),
                new TelemetryData(
                    stopwatch.ElapsedMilliseconds,
                    searchResult.Scores.ToList()));
        }
        catch (Exception ex)
        {
            stopwatch.Stop();

            _ragLogger.LogError(
                ex,
                "RAG query processing failed after {LatencyMs} ms.",
                stopwatch.ElapsedMilliseconds);

            throw;
        }
    }

    public async Task<RagIngestResponse> IngestAsync(
        RagIngestRequest request,
        int userId,
        CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(request);

        try
        {
            var embedding = await _aiService.GenerateEmbeddingAsync(
                request.Content,
                cancellationToken);

            if (embedding.Length == 0)
            {
                throw new InvalidOperationException(
                    "Embedding generation returned no vectors for the supplied content.");
            }

            var document = new ResearchDocument
            {
                Id = Guid.NewGuid(),
                Title = request.Title,
                Content = request.Content,
                Source = IngestSource,
                BodyZone = request.BodyZone,
                UserId = userId,
                Embedding = new Vector(embedding)
            };

            await _documentRepository.AddDocumentAsync(document, cancellationToken);

            _ragLogger.LogInfo(
                "Vector inserted. DocumentId={DocumentId}, UserId={UserId}, " +
                "BodyZone={BodyZone}, Dimensions={Dimensions}.",
                document.Id,
                userId,
                document.BodyZone,
                embedding.Length);

            return new RagIngestResponse(
                document.Id,
                document.Title,
                document.BodyZone,
                userId,
                embedding.Length,
                "Document ingested successfully.");
        }
        catch (Exception ex)
        {
            _ragLogger.LogError(
                ex,
                "Document ingestion failed. UserId={UserId}, Title={Title}, BodyZone={BodyZone}.",
                userId,
                request.Title,
                request.BodyZone);

            throw;
        }
    }
}
