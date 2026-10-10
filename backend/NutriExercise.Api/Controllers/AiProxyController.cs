using Microsoft.AspNetCore.Mvc;
using NutriExercise.Core.Interfaces;

namespace NutriExercise.Api.Controllers;

[ApiController]
[Route("api/ai")]
public class AiProxyController : ControllerBase
{
    private readonly IAiService _aiService;

    public AiProxyController(IAiService aiService)
    {
        _aiService = aiService;
    }

    [HttpPost("chat")]
    public async Task<IActionResult> Chat(
        [FromBody] ChatRequest request,
        CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(request.Message))
        {
            return BadRequest("Message is required.");
        }

        var reply = await _aiService.GenerateRoutineAsync(
            request.Message,
            cancellationToken);

        return Ok(new
        {
            Id = Guid.NewGuid(),
            Message = reply,
            Model = "llama3",
            CreatedAt = DateTime.UtcNow,
        });
    }
}

public class ChatRequest
{
    public string Message { get; set; } = string.Empty;

    public List<ChatTurnDto> History { get; set; } = new();
}

public class ChatTurnDto
{
    public string Role { get; set; } = string.Empty;

    public string Content { get; set; } = string.Empty;
}
