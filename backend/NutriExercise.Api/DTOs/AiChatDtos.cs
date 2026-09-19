namespace NutriExercise.Api.DTOs;

/// <summary>A single prior conversational turn supplied by the client.</summary>
public class ChatTurnDto
{
    public string Role { get; set; } = string.Empty;

    public string Content { get; set; } = string.Empty;
}

/// <summary>Request body for <c>POST /api/aiproxy/chat</c>.</summary>
public class ChatRequest
{
    public string Message { get; set; } = string.Empty;

    public List<ChatTurnDto> History { get; set; } = new();
}

/// <summary>Response body for <c>POST /api/aiproxy/chat</c>.</summary>
public record ChatResponseDto(Guid Id, string Message, string Model, DateTime CreatedAt);
