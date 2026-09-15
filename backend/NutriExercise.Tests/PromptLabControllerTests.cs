using FluentAssertions;
using Microsoft.AspNetCore.Mvc;
using Moq;
using NutriExercise.Api.Controllers;
using NutriExercise.Core.DTOs;
using NutriExercise.Core.Interfaces;

namespace NutriExercise.Tests;

public class PromptLabControllerTests
{
    private readonly Mock<IVectorSearchService> _vectorSearchMock = new();
    private readonly Mock<IAiModelService> _aiModelMock = new();

    private PromptLabController CreateController()
    {
        return new PromptLabController(
            _vectorSearchMock.Object,
            _aiModelMock.Object);
    }

    [Fact]
    public async Task RunQuery_WithValidPayload_ReturnsOkWithResponseAndCount()
    {
        var request = new PromptLabRunRequest(
            "Prompt",
            0.7,
            0.8,
            "Query");
        var contexts = new List<string> { "ctx1", "ctx2" };
        _vectorSearchMock
            .Setup(s => s.SearchAsync(
                request.TestQuery,
                request.SimilarityThreshold,
                It.IsAny<CancellationToken>()))
            .ReturnsAsync(contexts);
        _aiModelMock
            .Setup(s => s.GenerateAsync(
                request.SystemPrompt,
                request.TestQuery,
                contexts,
                request.Temperature,
                It.IsAny<CancellationToken>()))
            .ReturnsAsync("generated");

        var controller = CreateController();

        var result = await controller.RunQuery(request);

        var okResult = result.Should().BeOfType<OkObjectResult>().Subject;
        var response = okResult.Value.Should()
            .BeOfType<PromptLabRunResponse>().Subject;
        response.GeneratedResponse.Should().Be("generated");
        response.RetrievedContextCount.Should().Be(2);
        _vectorSearchMock.Verify(
            s => s.SearchAsync(
                request.TestQuery,
                request.SimilarityThreshold,
                It.IsAny<CancellationToken>()),
            Times.Once);
        _aiModelMock.Verify(
            s => s.GenerateAsync(
                request.SystemPrompt,
                request.TestQuery,
                contexts,
                request.Temperature,
                It.IsAny<CancellationToken>()),
            Times.Once);
    }

    [Theory]
    [InlineData(-0.1, 0.8, "Prompt", "Query",
        "Temperature must be between 0.0 and 1.0.")]
    [InlineData(1.1, 0.8, "Prompt", "Query",
        "Temperature must be between 0.0 and 1.0.")]
    [InlineData(0.7, -0.1, "Prompt", "Query",
        "SimilarityThreshold must be between 0.0 and 1.0.")]
    [InlineData(0.7, 1.1, "Prompt", "Query",
        "SimilarityThreshold must be between 0.0 and 1.0.")]
    [InlineData(0.7, 0.8, "", "Query",
        "SystemPrompt is required.")]
    [InlineData(0.7, 0.8, "Prompt", "",
        "TestQuery is required.")]
    public async Task RunQuery_WithInvalidPayload_ReturnsBadRequest(
        double temperature,
        double threshold,
        string systemPrompt,
        string testQuery,
        string expectedMessage)
    {
        var request = new PromptLabRunRequest(
            systemPrompt,
            temperature,
            threshold,
            testQuery);

        var controller = CreateController();

        var result = await controller.RunQuery(request);

        var badRequest = result.Should()
            .BeOfType<BadRequestObjectResult>().Subject;
        badRequest.Value.Should().Be(expectedMessage);
    }

    [Fact]
    public async Task RunQuery_WithNullSystemPrompt_ReturnsBadRequest()
    {
        var request = new PromptLabRunRequest(
            null!,
            0.7,
            0.8,
            "Query");

        var controller = CreateController();

        var result = await controller.RunQuery(request);

        result.Should().BeOfType<BadRequestObjectResult>();
    }

    [Fact]
    public async Task RunQuery_WithNullTestQuery_ReturnsBadRequest()
    {
        var request = new PromptLabRunRequest(
            "Prompt",
            0.7,
            0.8,
            null!);

        var controller = CreateController();

        var result = await controller.RunQuery(request);

        result.Should().BeOfType<BadRequestObjectResult>();
    }
}
