using Microsoft.AspNetCore.Mvc;
using NutriExercise.Api.Controllers;
using NutriExercise.Core.Interfaces;

namespace NutriExercise.Tests;

public class AiProxyControllerTests
{
    [Fact]
    public async Task Chat_Returns_BadRequest_When_Message_Is_Blank()
    {
        var controller = new AiProxyController(new StubAiService());

        var result = await controller.Chat(
            new ChatRequest { Message = "  " },
            CancellationToken.None);

        Assert.IsType<BadRequestObjectResult>(result);
    }

    [Fact]
    public async Task Chat_Returns_Message_Envelope()
    {
        var controller = new AiProxyController(new StubAiService());

        var result = await controller.Chat(
            new ChatRequest
            {
                Message = "Push pull 4 days",
                History = new List<ChatTurnDto>
                {
                    new() { Role = "user", Content = "hi" },
                },
            },
            CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        Assert.NotNull(ok.Value);
        var json = System.Text.Json.JsonSerializer.Serialize(ok.Value);
        Assert.Contains("message", json, StringComparison.OrdinalIgnoreCase);
        Assert.Contains("hello from stub", json);
    }

    private sealed class StubAiService : IAiService
    {
        public Task<string> GenerateRoutineAsync(
            string userPreferences,
            CancellationToken cancellationToken = default)
            => Task.FromResult("hello from stub");

        public Task<string> GenerateJsonAsync(
            string userInput,
            CancellationToken cancellationToken = default)
            => Task.FromResult("{}");

        public Task<float[]> GenerateEmbeddingAsync(
            string text,
            CancellationToken cancellationToken = default)
            => Task.FromResult(Array.Empty<float>());
    }
}
