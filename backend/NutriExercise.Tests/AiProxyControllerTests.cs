using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Moq;
using NutriExercise.Api.Controllers;
using NutriExercise.Api.DTOs;
using NutriExercise.Core.Entities;
using NutriExercise.Core.Interfaces;
using NutriExercise.Infrastructure.Data;

namespace NutriExercise.Tests;

public class AiProxyControllerTests
{
    private readonly Mock<IAiService> _aiService = new();
    private readonly Mock<IResearchDocumentRepository> _documents = new();
    private readonly List<AiInteraction> _persisted = new();

    public AiProxyControllerTests()
    {
        _aiService
            .Setup(s => s.GenerateEmbeddingAsync(It.IsAny<string>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(new float[] { 0.1f, 0.2f });
        StubDocuments();
    }

    private void StubDocuments(params string[] contents)
    {
        var docs = contents
            .Select(content => new ResearchDocument { Content = content })
            .ToList();

        _documents
            .Setup(r => r.SearchSimilarDocumentsAsync(
                It.IsAny<float[]>(), It.IsAny<int>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(docs);
    }

    private void StubReply(string reply, Action<string>? capture = null)
    {
        _aiService
            .Setup(s => s.GenerateChatAsync(It.IsAny<string>(), It.IsAny<CancellationToken>()))
            .Callback<string, CancellationToken>((prompt, _) => capture?.Invoke(prompt))
            .ReturnsAsync(reply);
    }

    private AiProxyController CreateController()
    {
        var dbSet = new Mock<DbSet<AiInteraction>>();
        dbSet.Setup(d => d.Add(It.IsAny<AiInteraction>())).Callback<AiInteraction>(_persisted.Add);

        var dbContext = new Mock<AppDbContext>(new DbContextOptions<AppDbContext>());
        dbContext.Setup(c => c.AiInteractions).Returns(dbSet.Object);
        dbContext
            .Setup(c => c.SaveChangesAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(1);

        return new AiProxyController(_aiService.Object, _documents.Object, dbContext.Object);
    }

    [Fact]
    public async Task Chat_EmptyMessage_ReturnsBadRequest()
    {
        var result = await CreateController().Chat(
            new ChatRequest { Message = "   " },
            CancellationToken.None);

        Assert.IsType<BadRequestObjectResult>(result);
        _aiService.Verify(
            s => s.GenerateChatAsync(It.IsAny<string>(), It.IsAny<CancellationToken>()),
            Times.Never);
        Assert.Empty(_persisted);
    }

    [Fact]
    public async Task Chat_WithDocuments_ReturnsGroundedReplyAndPersistsInteraction()
    {
        StubDocuments("ACSM hypertrophy volume");
        string? capturedPrompt = null;
        StubReply("Here is your routine", prompt => capturedPrompt = prompt);

        var result = await CreateController().Chat(
            new ChatRequest { Message = "Build mass" },
            CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        var response = Assert.IsType<ChatResponseDto>(ok.Value);
        Assert.Equal("Here is your routine", response.Message);
        Assert.Equal("llama3-rag", response.Model);
        Assert.NotNull(capturedPrompt);
        Assert.Contains("ACSM hypertrophy volume", capturedPrompt);
        Assert.Single(_persisted);
    }

    [Fact]
    public async Task Chat_NoDocuments_UsesUngroundedModel()
    {
        StubReply("ok");

        var result = await CreateController().Chat(
            new ChatRequest { Message = "Hi" },
            CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        var response = Assert.IsType<ChatResponseDto>(ok.Value);
        Assert.Equal("llama3", response.Model);
    }

    [Fact]
    public async Task Chat_EmbeddingFails_StillRepliesUngrounded()
    {
        _aiService
            .Setup(s => s.GenerateEmbeddingAsync(It.IsAny<string>(), It.IsAny<CancellationToken>()))
            .ThrowsAsync(new HttpRequestException("ollama down"));
        StubReply("ok");

        var result = await CreateController().Chat(
            new ChatRequest { Message = "Hi" },
            CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        var response = Assert.IsType<ChatResponseDto>(ok.Value);
        Assert.Equal("llama3", response.Model);
    }

    [Fact]
    public async Task Chat_LlmFails_ReturnsBadGatewayWithoutPersisting()
    {
        _aiService
            .Setup(s => s.GenerateChatAsync(It.IsAny<string>(), It.IsAny<CancellationToken>()))
            .ThrowsAsync(new HttpRequestException("ollama down"));

        var result = await CreateController().Chat(
            new ChatRequest { Message = "Hi" },
            CancellationToken.None);

        var status = Assert.IsType<ObjectResult>(result);
        Assert.Equal(StatusCodes.Status502BadGateway, status.StatusCode);
        Assert.Empty(_persisted);
    }

    [Fact]
    public async Task Chat_EmptyReply_ReturnsBadGateway()
    {
        StubReply("   ");

        var result = await CreateController().Chat(
            new ChatRequest { Message = "Hi" },
            CancellationToken.None);

        var status = Assert.IsType<ObjectResult>(result);
        Assert.Equal(StatusCodes.Status502BadGateway, status.StatusCode);
        Assert.Empty(_persisted);
    }

    [Fact]
    public async Task Chat_ForwardsHistoryInPrompt()
    {
        string? capturedPrompt = null;
        StubReply("ok", prompt => capturedPrompt = prompt);

        var request = new ChatRequest
        {
            Message = "Add a leg day",
            History = new List<ChatTurnDto>
            {
                new() { Role = "user", Content = "Push pull 4 days" },
                new() { Role = "assistant", Content = "Here is a split" }
            }
        };

        await CreateController().Chat(request, CancellationToken.None);

        Assert.NotNull(capturedPrompt);
        Assert.Contains("user: Push pull 4 days", capturedPrompt);
        Assert.Contains("assistant: Here is a split", capturedPrompt);
        Assert.Contains("Usuario: Add a leg day", capturedPrompt);
    }
}
