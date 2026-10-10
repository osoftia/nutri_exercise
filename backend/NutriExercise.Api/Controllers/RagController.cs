using System.Diagnostics;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using NutriExercise.Api.DTOs;
using NutriExercise.Api.Logging;
using NutriExercise.Core.Constants;
using NutriExercise.Core.Entities;
using NutriExercise.Core.Interfaces;
using NutriExercise.Infrastructure.Data;
using Pgvector;

namespace NutriExercise.Api.Controllers;

/// <summary>
/// RAG endpoints for knowledge ingestion and retrieval.
///
/// Both actions default to <c>UserId = 1</c> (seeded test user) when the
/// request carries no <c>Authorization</c> token, enabling the frontend
/// ingest form to work without login. All outcomes are traced with
/// <c>[RAG-INFO]:</c> / <c>[RAG-ERROR]:</c> prefixed logs.
/// </summary>
[ApiController]
[Route("api/rag")]
public class RagController : ControllerBase
{
    private readonly IAiService _aiService;
    private readonly IResearchDocumentRepository _documents;
    private readonly AppDbContext _dbContext;
    private readonly ILogger<RagController> _logger;

    public RagController(
        IAiService aiService,
        IResearchDocumentRepository documents,
        AppDbContext dbContext,
        ILogger<RagController> logger)
    {
        _aiService = aiService;
        _documents = documents;
        _dbContext = dbContext;
        _logger = logger;
    }

    /// <summary>
    /// Ingests a custom document: embeds <c>Content</c> via the LLM,
    /// stores the pgvector row and associates it with the effective user.
    /// </summary>
    [HttpPost("ingest")]
    public async Task<IActionResult> Ingest(
        [FromBody] RagIngestRequest request,
        CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(request.Title) ||
            string.IsNullOrWhiteSpace(request.Content) ||
            string.IsNullOrWhiteSpace(request.BodyZone))
        {
            _logger.LogRagError(
                "ingest validation failed — Title, Content and BodyZone are required (Title = '{Title}').",
                request.Title);
            return BadRequest("Title, Content, and BodyZone are required.");
        }

        var userId = request.ResolveUserId(HasAuthToken());
        var stopwatch = Stopwatch.StartNew();

        try
        {
            var embedding = await _aiService.GenerateEmbeddingAsync(request.Content, cancellationToken);
            if (embedding.Length == 0)
            {
                _logger.LogRagError(
                    "embedding generation returned empty vector for ingest (Title = '{Title}', UserId = {UserId}).",
                    request.Title, userId);
                return StatusCode(StatusCodes.Status502BadGateway, "Failed to generate embedding.");
            }

            var document = new ResearchDocument
            {
                Id = Guid.NewGuid(),
                Title = request.Title.Trim(),
                Content = request.Content,
                Source = request.BodyZone.Trim(),
                BodyZone = request.BodyZone.Trim(),
                UserId = userId,
                Embedding = new Vector(embedding),
            };

            await _documents.AddDocumentAsync(document, cancellationToken);
            stopwatch.Stop();

            _logger.LogRagInfo(
                "vector insertion succeeded — document '{Title}' ingested for UserId = {UserId} (DocumentId = {DocumentId}, BodyZone = '{BodyZone}', LatencyMs = {LatencyMs}).",
                document.Title, userId, document.Id, document.BodyZone, stopwatch.ElapsedMilliseconds);

            return Ok(new RagIngestResponse(document.Id, userId, "Document ingested successfully."));
        }
        catch (Exception ex) when (IsVectorException(ex))
        {
            _logger.LogRagError(
                ex,
                "pgvector exception while ingesting document '{Title}' for UserId = {UserId}.",
                request.Title, userId);
            return StatusCode(StatusCodes.Status502BadGateway, "Vector store failure during ingestion.");
        }
        catch (Exception ex) when (ex is DbUpdateException or Npgsql.NpgsqlException)
        {
            _logger.LogRagError(
                ex,
                "database connectivity failure while ingesting document '{Title}' for UserId = {UserId}.",
                request.Title, userId);
            return StatusCode(StatusCodes.Status503ServiceUnavailable, "Database unavailable during ingestion.");
        }
        catch (Exception ex)
        {
            _logger.LogRagError(
                ex,
                "internal processing error while ingesting document '{Title}' for UserId = {UserId}.",
                request.Title, userId);
            return StatusCode(StatusCodes.Status500InternalServerError, "Internal ingestion error.");
        }
    }

    /// <summary>
    /// Executes a RAG query: embeds the prompt, retrieves similar pgvector
    /// documents, generates the answer and persists the interaction audit.
    /// </summary>
    [HttpPost("query")]
    public async Task<IActionResult> Query(
        [FromBody] RagQueryRequest request,
        CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(request.Query))
        {
            _logger.LogRagError("query validation failed — Query is required.");
            return BadRequest("Query is required.");
        }

        var userId = request.ResolveUserId(HasAuthToken());
        var stopwatch = Stopwatch.StartNew();

        try
        {
            var queryVector = await _aiService.GenerateEmbeddingAsync(request.Query, cancellationToken);
            if (queryVector.Length == 0)
            {
                _logger.LogRagError(
                    "embedding generation returned empty vector for query (UserId = {UserId}).", userId);
                return StatusCode(StatusCodes.Status502BadGateway, "Failed to generate embedding.");
            }

            var matches = await _documents.SearchSimilarDocumentsAsync(queryVector, limit: 5, cancellationToken);
            var contextText = string.Join("\n", matches.Select(d => d.Content));
            var augmentedPrompt =
                $"System: {request.SystemPrompt}\nContext:\n{contextText}\n\nUser query: {request.Query}";

            var answer = await _aiService.GenerateRoutineAsync(augmentedPrompt, cancellationToken);
            stopwatch.Stop();

            var interaction = new AiInteraction
            {
                Id = Guid.NewGuid(),
                UserPrompt = request.Query,
                GeneratedRoutine = answer,
                ModelUsed = "llama3-RAG",
                UsedContext = contextText,
                CreatedAt = DateTime.UtcNow,
                UserId = userId,
            };
            _dbContext.AiInteractions.Add(interaction);
            await _dbContext.SaveChangesAsync(cancellationToken);

            var tokensPerSecond = stopwatch.ElapsedMilliseconds > 0
                ? Math.Round(answer.Length / Math.Max(stopwatch.Elapsed.TotalSeconds, 0.001), 2)
                : 0;

            _logger.LogRagInfo(
                "query executed successfully for UserId = {UserId} (Matches = {Matches}, LatencyMs = {LatencyMs}, Throughput = {TokensPerSecond} tok/s).",
                userId, matches.Count, stopwatch.ElapsedMilliseconds, tokensPerSecond);

            var response = new RagQueryResponse(
                answer,
                matches.Select(m => new RagMatchDto(
                    m.Id.ToString(), m.Title, CosineSimilarityToScore(m, queryVector), m.Content)).ToList(),
                new RagTelemetryDto((int)stopwatch.ElapsedMilliseconds, tokensPerSecond));

            return Ok(response);
        }
        catch (Exception ex) when (IsVectorException(ex))
        {
            _logger.LogRagError(ex, "pgvector exception while executing query for UserId = {UserId}.", userId);
            return StatusCode(StatusCodes.Status502BadGateway, "Vector store failure during query.");
        }
        catch (Exception ex) when (ex is DbUpdateException or Npgsql.NpgsqlException)
        {
            _logger.LogRagError(ex, "database connectivity failure while executing query for UserId = {UserId}.", userId);
            return StatusCode(StatusCodes.Status503ServiceUnavailable, "Database unavailable during query.");
        }
        catch (Exception ex)
        {
            _logger.LogRagError(ex, "internal processing error while executing query for UserId = {UserId}.", userId);
            return StatusCode(StatusCodes.Status500InternalServerError, "Internal query error.");
        }
    }

    private bool HasAuthToken()
    {
        if (Request.Headers.TryGetValue("Authorization", out var values))
        {
            return !string.IsNullOrWhiteSpace(values.ToString());
        }
        return false;
    }

    private static bool IsVectorException(Exception ex) =>
        ex.GetType().FullName?.Contains("Pgvector", StringComparison.OrdinalIgnoreCase) == true
        || ex.GetType().FullName?.Contains("Vector", StringComparison.OrdinalIgnoreCase) == true
        || (ex.InnerException is not null && IsVectorException(ex.InnerException));

    private static double CosineSimilarityToScore(ResearchDocument document, float[] queryVector)
    {
        try
        {
            var stored = document.Embedding?.ToArray();
            if (stored is null || stored.Length != queryVector.Length || stored.Length == 0)
            {
                return 0;
            }
            double dot = 0, normA = 0, normB = 0;
            for (var i = 0; i < stored.Length; i++)
            {
                dot += stored[i] * queryVector[i];
                normA += stored[i] * stored[i];
                normB += queryVector[i] * queryVector[i];
            }
            if (normA == 0 || normB == 0)
            {
                return 0;
            }
            return Math.Clamp(dot / (Math.Sqrt(normA) * Math.Sqrt(normB)), 0, 1);
        }
        catch
        {
            return 0;
        }
    }
}
