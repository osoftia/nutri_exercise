using System.Globalization;
using System.Text.Json;
using FluentAssertions;
using Microsoft.AspNetCore.Mvc;
using Moq;
using NutriExercise.Api.Controllers;
using NutriExercise.Core.DTOs;
using NutriExercise.Core.Interfaces;
using Reqnroll;

namespace NutriExercise.Specs.Steps;

[Binding]
public class PromptLabSteps
{
    private readonly Mock<IVectorSearchService> _vectorSearchMock = new();
    private readonly Mock<IAiModelService> _aiModelMock = new();
    private PromptLabController? _controller;
    private IActionResult? _result;

    [Given(@"the Prompt Lab API is running")]
    public void GivenThePromptLabApiIsRunning()
    {
        var contexts = new List<string> { "Hypertrophy context", "Nutrition context" };

        _vectorSearchMock
            .Setup(s => s.SearchAsync(
                It.IsAny<string>(),
                It.IsAny<double>(),
                It.IsAny<CancellationToken>()))
            .ReturnsAsync(contexts);

        _aiModelMock
            .Setup(s => s.GenerateAsync(
                It.IsAny<string>(),
                It.IsAny<string>(),
                It.IsAny<IReadOnlyList<string>>(),
                It.IsAny<double>(),
                It.IsAny<CancellationToken>()))
            .ReturnsAsync("generated response");

        _controller = new PromptLabController(
            _vectorSearchMock.Object,
            _aiModelMock.Object);
    }

    [When(@"a POST request is sent to ""/api/PromptLab/run-query"" with valid payload \(Temp: (.*), Threshold: (.*)\)")]
    public async Task WhenAPostRequestIsSentWithValidPayload(
        string temperature,
        string threshold)
    {
        ArgumentNullException.ThrowIfNull(temperature);
        ArgumentNullException.ThrowIfNull(threshold);

        var request = new PromptLabRunRequest(
            "Prompt",
            ParseDouble(temperature),
            ParseDouble(threshold),
            "Query");

        _result = await _controller!.RunQuery(request);
    }

    [When(@"a POST request is sent to ""/api/PromptLab/run-query"" with (.*), (.*), (.*), and (.*)")]
    public async Task WhenAPostRequestIsSentWithParameters(
        string temperature,
        string threshold,
        string systemPrompt,
        string testQuery)
    {
        ArgumentNullException.ThrowIfNull(temperature);
        ArgumentNullException.ThrowIfNull(threshold);
        ArgumentNullException.ThrowIfNull(systemPrompt);
        ArgumentNullException.ThrowIfNull(testQuery);

        var request = new PromptLabRunRequest(
            Unquote(systemPrompt),
            ParseDouble(temperature),
            ParseDouble(threshold),
            Unquote(testQuery));

        _result = await _controller!.RunQuery(request);
    }

    [Then(@"the response status should be 200 OK")]
    public void ThenTheResponseStatusShouldBe200Ok()
    {
        _result.Should().BeOfType<OkObjectResult>();
    }

    [Then(@"the response status should be 400 Bad Request")]
    public void ThenTheResponseStatusShouldBe400BadRequest()
    {
        _result.Should().BeOfType<BadRequestObjectResult>();
    }

    [Then(@"the response should contain the ""(.*)""")]
    public void ThenTheResponseShouldContain(string propertyName)
    {
        var okResult = _result as OkObjectResult;
        okResult.Should().NotBeNull();

        var json = JsonSerializer.Serialize(okResult!.Value);
        json.Should().Contain(propertyName);
    }

    [Then(@"the response should contain the error message (.*)")]
    public void ThenTheResponseShouldContainTheErrorMessage(string expectedMessage)
    {
        var badRequest = _result as BadRequestObjectResult;
        badRequest.Should().NotBeNull();

        var message = badRequest!.Value as string;
        message.Should().Be(Unquote(expectedMessage));
    }

    [Then(@"the vector search and AI model services must be called exactly once")]
    public void ThenTheServicesMustBeCalledExactlyOnce()
    {
        _vectorSearchMock.Verify(
            s => s.SearchAsync(
                It.IsAny<string>(),
                It.IsAny<double>(),
                It.IsAny<CancellationToken>()),
            Times.Once);

        _aiModelMock.Verify(
            s => s.GenerateAsync(
                It.IsAny<string>(),
                It.IsAny<string>(),
                It.IsAny<IReadOnlyList<string>>(),
                It.IsAny<double>(),
                It.IsAny<CancellationToken>()),
            Times.Once);
    }

    private static double ParseDouble(string value) =>
        double.Parse(value.Trim(), CultureInfo.InvariantCulture);

    private static string Unquote(string value)
    {
        value = value.Trim();

        if (value.Length >= 2 &&
            value.StartsWith('"') &&
            value.EndsWith('"'))
        {
            return value[1..^1];
        }

        return value;
    }
}
