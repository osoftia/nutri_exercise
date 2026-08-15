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

    public KnowledgeController(IAiService aiService, IResearchDocumentRepository researchDocumentRepository)
    {
        _aiService = aiService;
        _researchDocumentRepository = researchDocumentRepository;
    }

    [HttpPost("document")]
    public async Task<IActionResult> AddDocument([FromBody] AddDocumentRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.Title) ||
            string.IsNullOrWhiteSpace(request.Content) ||
            string.IsNullOrWhiteSpace(request.Source))
        {
            return BadRequest("Title, Content, and Source are required.");
        }

        var embeddingArray = await _aiService.GenerateEmbeddingAsync(request.Content);

        if (embeddingArray.Length == 0)
        {
            return StatusCode(StatusCodes.Status502BadGateway, "Failed to generate embedding.");
        }

        var document = new ResearchDocument
        {
            Id = Guid.NewGuid(),
            Title = request.Title,
            Content = request.Content,
            Source = request.Source,
            Embedding = new Vector(embeddingArray)
        };

        await _researchDocumentRepository.AddDocumentAsync(document);

        return Ok(new { Message = "Document ingested successfully.", Id = document.Id });
    }
}

public record AddDocumentRequest(string Title, string Content, string Source);
