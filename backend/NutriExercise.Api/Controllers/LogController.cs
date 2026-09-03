using System.Text.Json;
using Microsoft.AspNetCore.Mvc;
using NutriExercise.Api.DTOs;
using NutriExercise.Core.Interfaces;

namespace NutriExercise.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class LogController : ControllerBase
{
    private readonly IAiService _aiService;

    public LogController(IAiService aiService)
    {
        _aiService = aiService;
    }

    [HttpPost("parse")]
    public async Task<IActionResult> Parse([FromBody] ParseLogRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.Text))
        {
            return BadRequest("Log text is required.");
        }

        var json = await _aiService.GenerateJsonAsync(request.Text);
        var response = JsonSerializer.Deserialize<ParsedLogResponse>(
            json,
            new JsonSerializerOptions { PropertyNameCaseInsensitive = true });

        if (response is null)
        {
            return BadRequest("Unable to parse the log into a structured response.");
        }

        return Ok(response);
    }
}
