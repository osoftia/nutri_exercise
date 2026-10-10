using Microsoft.AspNetCore.Mvc;
using NutriExercise.Api.Logging;
using NutriExercise.Core.Constants;
using NutriExercise.Core.Entities;
using NutriExercise.Core.Interfaces;
using Pgvector;

namespace NutriExercise.Api.Controllers;

[ApiController]
[Route("api/knowledge")]
public class KnowledgeController : ControllerBase
{
    private readonly IAiService _aiService;
    private readonly IResearchDocumentRepository _researchDocumentRepository;
    private readonly ILogger<KnowledgeController> _logger;

    public KnowledgeController(
        IAiService aiService,
        IResearchDocumentRepository researchDocumentRepository,
        ILogger<KnowledgeController> logger)
    {
        _aiService = aiService;
        _researchDocumentRepository = researchDocumentRepository;
        _logger = logger;
    }

    [HttpPost("document")]
    public async Task<IActionResult> AddDocument([FromBody] AddDocumentRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.Title) ||
            string.IsNullOrWhiteSpace(request.Content) ||
            string.IsNullOrWhiteSpace(request.Source))
        {
            _logger.LogRagError("knowledge ingest validation failed — Title, Content and Source are required.");
            return BadRequest("Title, Content, and Source are required.");
        }

        // Legacy endpoint: no auth concept — always attribute to the default test user.
        var userId = RagDefaults.ResolveUserId(request.UserId);

        float[] embeddingArray;
        try
        {
            embeddingArray = await _aiService.GenerateEmbeddingAsync(request.Content);
        }
        catch (Exception ex)
        {
            _logger.LogRagError(ex, "pgvector exception while embedding knowledge document '{Title}'.", request.Title);
            return StatusCode(StatusCodes.Status502BadGateway, "Failed to generate embedding.");
        }

        if (embeddingArray.Length == 0)
        {
            _logger.LogRagError("embedding generation returned empty vector for '{Title}'.", request.Title);
            return StatusCode(StatusCodes.Status502BadGateway, "Failed to generate embedding.");
        }

        var document = new ResearchDocument
        {
            Id = Guid.NewGuid(),
            Title = request.Title,
            Content = request.Content,
            Source = request.Source,
            BodyZone = request.Source,
            UserId = userId,
            Embedding = new Vector(embeddingArray)
        };

        try
        {
            await _researchDocumentRepository.AddDocumentAsync(document);
        }
        catch (Exception ex)
        {
            _logger.LogRagError(ex, "database connectivity failure while storing knowledge document '{Title}'.", request.Title);
            return StatusCode(StatusCodes.Status503ServiceUnavailable, "Database unavailable during ingestion.");
        }

        _logger.LogRagInfo(
            "vector insertion succeeded — knowledge document '{Title}' ingested for UserId = {UserId} (DocumentId = {DocumentId}).",
            document.Title, userId, document.Id);

        return Ok(new { Message = "Document ingested successfully.", Id = document.Id });
    }

    [HttpPost("seed")]
    public async Task<IActionResult> Seed()
    {
        if (await _researchDocumentRepository.HasDocumentsAsync())
        {
            return BadRequest("La base de datos ya contiene documentos.");
        }

        var documents = new[]
        {
            new { Title = "ACSM Position Stand 2026", Source = "ACSM", Content = "Para optimizar la hipertrofia muscular, el volumen de entrenamiento debe ser de al menos 10 series semanales por grupo muscular. La carga puede variar entre el 30% y el 100% del 1RM siempre que las series se lleven cerca del fallo muscular." },
            new { Title = "Resistance Training Variables", Source = "NIH Umbrella Review", Content = "El descanso entre series para maximizar el crecimiento miofibrilar debe ser de 2 a 3 minutos para permitir la recuperación del sistema nervioso central. El entrenamiento al fallo es más crucial cuando se utilizan cargas ligeras." },
            new { Title = "Nutritional Supplements Evidence 2025", Source = "PubMed Morphology", Content = "Para hipertrofia, la ingesta de proteína óptima es de 1.6 g a 2.2 g por kilogramo de peso corporal al día. La creatina monohidrato (5g diarios) actúa como amplificador celular, mientras que el HMB es condicional." }
        };

        foreach (var item in documents)
        {
            Vector vector;
            try
            {
                var vectorArray = await _aiService.GenerateEmbeddingAsync(item.Content);
                vector = new Vector(vectorArray);
            }
            catch (Exception ex)
            {
                _logger.LogRagError(ex, "pgvector exception while seeding knowledge document '{Title}'.", item.Title);
                return StatusCode(StatusCodes.Status502BadGateway, "Failed to generate embedding.");
            }

            var doc = new ResearchDocument
            {
                Id = Guid.NewGuid(),
                Title = item.Title,
                Content = item.Content,
                Source = item.Source,
                BodyZone = item.Source,
                UserId = RagDefaults.DefaultUserId,
                Embedding = vector
            };

            try
            {
                await _researchDocumentRepository.AddDocumentAsync(doc);
            }
            catch (Exception ex)
            {
                _logger.LogRagError(ex, "database connectivity failure while seeding knowledge document '{Title}'.", item.Title);
                return StatusCode(StatusCodes.Status503ServiceUnavailable, "Database unavailable during seeding.");
            }
        }

        _logger.LogRagInfo("database seeding completed — scientific knowledge injected (Documents = 3).");
        return Ok("Conocimiento científico inyectado correctamente.");
    }
}

public record AddDocumentRequest(string Title, string Content, string Source, int? UserId = null);
