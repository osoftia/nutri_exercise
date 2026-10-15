using System.Text.Json;
using FluentAssertions;
using Microsoft.AspNetCore.Mvc;
using Moq;
using NutriExercise.Api.Controllers;
using NutriExercise.Core.DTOs;
using NutriExercise.Core.Entities;
using NutriExercise.Core.Interfaces;
using NutriExercise.Infrastructure.Services;
using Reqnroll;

namespace NutriExercise.Specs.Steps;

[Binding]
public class RagQuerySteps
{
    private RagController? _controller;
    private IActionResult? _result;

    [Given(@"the RAG API is running")]
    public void GivenTheRagApiIsRunning()
    {
        var userRepository = new Mock<IUserRepository>();
        userRepository
            .Setup(r => r.EnsureSeedUserAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(new User { Id = 1, Name = "Test User", Email = "t@x.io" });

        var ragLogger = new Mock<IRagLogger>();

        _controller = new RagController(
            new MockRagOrchestrator(ragLogger.Object),
            userRepository.Object,
            ragLogger.Object);
    }

    [When(@"a POST request is sent to ""(.*)"" with a valid payload")]
    public async Task WhenAPostRequestIsSentWithAValidPayload(string endpoint)
    {
        ArgumentNullException.ThrowIfNull(endpoint);

        var request = new RagRequest("Prompt", 0.7, 0.8, "Query");

        _result = await _controller!.Query(request);
    }

    [Then(@"the RAG response status should be 200 OK")]
    public void ThenTheRagResponseStatusShouldBe200Ok()
    {
        _result.Should().BeOfType<OkObjectResult>();
    }

    [Then(@"the RAG response should contain ""(.*)""")]
    public void ThenTheRagResponseShouldContain(string propertyName)
    {
        ArgumentNullException.ThrowIfNull(propertyName);

        var okResult = _result as OkObjectResult;
        okResult.Should().NotBeNull();

        var json = JsonSerializer.Serialize(okResult!.Value);
        json.Should().Contain(propertyName);
    }

    [Then(@"the RAG telemetry should report a non-negative latency")]
    public void ThenTheRagTelemetryShouldReportANonNegativeLatency()
    {
        var okResult = _result as OkObjectResult;
        var response = okResult!.Value as RagResponse;

        response.Should().NotBeNull();
        response!.Telemetry.LatencyMs.Should().BeGreaterThanOrEqualTo(0);
    }
}
