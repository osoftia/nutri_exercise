using System.Text.Json;
using FluentAssertions;
using Microsoft.AspNetCore.Mvc;
using NutriExercise.Api.Controllers;
using NutriExercise.Core.DTOs;
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
        _controller = new RagController();
    }

    [When(@"a POST request is sent to ""(.*)"" with a valid payload")]
    public void WhenAPostRequestIsSentWithAValidPayload(string endpoint)
    {
        ArgumentNullException.ThrowIfNull(endpoint);

        var request = new RagRequest("Prompt", 0.7, 0.8, "Query");

        _result = _controller!.Query(request);
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
