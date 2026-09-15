using Microsoft.AspNetCore.Mvc;
using NutriExercise.Core.DTOs;
using NutriExercise.Core.Interfaces;

namespace NutriExercise.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class PromptLabController : ControllerBase
{
    private readonly IVectorSearchService _vectorSearchService;
    private readonly IAiModelService _aiModelService;

    public PromptLabController(
        IVectorSearchService vectorSearchService,
        IAiModelService aiModelService)
    {
        ArgumentNullException.ThrowIfNull(vectorSearchService);
        ArgumentNullException.ThrowIfNull(aiModelService);

        _vectorSearchService = vectorSearchService;
        _aiModelService = aiModelService;
    }

    [HttpPost("run-query")]
    public async Task<IActionResult> RunQuery(
        [FromBody] PromptLabRunRequest request,
        CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(request);

        if (string.IsNullOrWhiteSpace(request.SystemPrompt))
        {
            return BadRequest("SystemPrompt is required.");
        }

        if (string.IsNullOrWhiteSpace(request.TestQuery))
        {
            return BadRequest("TestQuery is required.");
        }

        if (request.Temperature < 0.0 || request.Temperature > 1.0)
        {
            return BadRequest(
                "Temperature must be between 0.0 and 1.0.");
        }

        if (request.SimilarityThreshold < 0.0
            || request.SimilarityThreshold > 1.0)
        {
            return BadRequest(
                "SimilarityThreshold must be between 0.0 and 1.0.");
        }

        var contexts = await _vectorSearchService.SearchAsync(
            request.TestQuery,
            request.SimilarityThreshold,
            cancellationToken);

        var generated = await _aiModelService.GenerateAsync(
            request.SystemPrompt,
            request.TestQuery,
            contexts,
            request.Temperature,
            cancellationToken);

        var response = new PromptLabRunResponse(
            generated,
            contexts.Count);

        return Ok(response);
    }
}
