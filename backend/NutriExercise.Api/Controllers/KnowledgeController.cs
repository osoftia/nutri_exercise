using Microsoft.AspNetCore.Mvc;
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
    private readonly IUserRepository _userRepository;
    private readonly IRagLogger _ragLogger;

    public KnowledgeController(
        IAiService aiService,
        IResearchDocumentRepository researchDocumentRepository,
        IUserRepository userRepository,
        IRagLogger ragLogger)
    {
        ArgumentNullException.ThrowIfNull(aiService);
        ArgumentNullException.ThrowIfNull(researchDocumentRepository);
        ArgumentNullException.ThrowIfNull(userRepository);
        ArgumentNullException.ThrowIfNull(ragLogger);

        _aiService = aiService;
        _researchDocumentRepository = researchDocumentRepository;
        _userRepository = userRepository;
        _ragLogger = ragLogger;
    }

    [HttpPost("document")]
    public async Task<IActionResult> AddDocument(
        [FromBody] AddDocumentRequest request,
        CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(request);

        if (string.IsNullOrWhiteSpace(request.Title) ||
            string.IsNullOrWhiteSpace(request.Content) ||
            string.IsNullOrWhiteSpace(request.Source))
        {
            return BadRequest("Title, Content, and Source are required.");
        }

        var userId = await ResolveUserIdAsync(request.UserId, cancellationToken);

        try
        {
            var embeddingArray = await _aiService.GenerateEmbeddingAsync(
                request.Content,
                cancellationToken);

            if (embeddingArray.Length == 0)
            {
                return StatusCode(
                    StatusCodes.Status502BadGateway,
                    "Failed to generate embedding.");
            }

            var document = new ResearchDocument
            {
                Id = Guid.NewGuid(),
                Title = request.Title,
                Content = request.Content,
                Source = request.Source,
                BodyZone = "General",
                UserId = userId,
                Embedding = new Vector(embeddingArray)
            };

            await _researchDocumentRepository.AddDocumentAsync(
                document,
                cancellationToken);

            _ragLogger.LogInfo(
                "Vector inserted. DocumentId={DocumentId}, UserId={UserId}, Dimensions={Dimensions}.",
                document.Id,
                userId,
                embeddingArray.Length);

            return Ok(new { Message = "Document ingested successfully.", Id = document.Id });
        }
        catch (Exception ex)
        {
            _ragLogger.LogError(
                ex,
                "Document ingestion failed for UserId={UserId}.",
                userId);

            throw;
        }
    }

    [HttpPost("seed")]
    public async Task<IActionResult> Seed(CancellationToken cancellationToken = default)
    {
        if (await _researchDocumentRepository.HasDocumentsAsync(cancellationToken))
        {
            return BadRequest("La base de datos ya contiene documentos.");
        }

        var userId = await ResolveUserIdAsync(null, cancellationToken);

        var documents = new[]
        {
            new { Title = "ACSM Position Stand 2026", Source = "ACSM", Content = "Para optimizar la hipertrofia muscular, el volumen de entrenamiento debe ser de al menos 10 series semanales por grupo muscular. La carga puede variar entre el 30% y el 100% del 1RM siempre que las series se lleven cerca del fallo muscular." },
            new { Title = "Resistance Training Variables", Source = "NIH Umbrella Review", Content = "El descanso entre series para maximizar el crecimiento miofibrilar debe ser de 2 a 3 minutos para permitir la recuperación del sistema nervioso central. El entrenamiento al fallo es más crucial cuando se utilizan cargas ligeras." },
            new { Title = "Nutritional Supplements Evidence 2025", Source = "PubMed Morphology", Content = "Para hipertrofia, la ingesta de proteína óptima es de 1.6 g a 2.2 g por kilogramo de peso corporal al día. La creatina monohidrato (5g diarios) actúa como amplificador celular, mientras que el HMB es condicional." }
        };

        try
        {
            foreach (var item in documents)
            {
                var vectorArray = await _aiService.GenerateEmbeddingAsync(
                    item.Content,
                    cancellationToken);

                var doc = new ResearchDocument
                {
                    Id = Guid.NewGuid(),
                    Title = item.Title,
                    Content = item.Content,
                    Source = item.Source,
                    BodyZone = "General",
                    UserId = userId,
                    Embedding = new Vector(vectorArray)
                };

                await _researchDocumentRepository.AddDocumentAsync(doc, cancellationToken);

                _ragLogger.LogInfo(
                    "Vector inserted. DocumentId={DocumentId}, UserId={UserId}, Dimensions={Dimensions}.",
                    doc.Id,
                    userId,
                    vectorArray.Length);
            }
        }
        catch (Exception ex)
        {
            _ragLogger.LogError(
                ex,
                "Knowledge seeding failed for UserId={UserId}.",
                userId);

            throw;
        }

        return Ok("Conocimiento científico inyectado correctamente.");
    }

    private async Task<int> ResolveUserIdAsync(
        int? requestedUserId,
        CancellationToken cancellationToken)
    {
        if (requestedUserId.HasValue && requestedUserId.Value > 0)
        {
            var user = await _userRepository.GetByIdAsync(
                requestedUserId.Value,
                cancellationToken);

            if (user is not null)
            {
                return user.Id;
            }
        }

        var defaultUser = await _userRepository.EnsureSeedUserAsync(cancellationToken);

        return defaultUser.Id;
    }
}

public record AddDocumentRequest(
    string Title,
    string Content,
    string Source,
    int? UserId = null);
