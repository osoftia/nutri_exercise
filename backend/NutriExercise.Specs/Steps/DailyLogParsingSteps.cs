using FluentAssertions;
using Microsoft.AspNetCore.Mvc;
using Moq;
using NutriExercise.Api.Controllers;
using NutriExercise.Api.DTOs;
using NutriExercise.Core.Interfaces;
using Reqnroll;

namespace NutriExercise.Specs.Steps;

[Binding]
public class DailyLogParsingSteps
{
    private readonly Mock<IAiService> _aiServiceMock = new();
    private LogController? _controller;
    private IActionResult? _result;
    private string _submittedText = string.Empty;

    [Given(@"the user submits the text: ""(.*)""")]
    public void GivenTheUserSubmitsTheText(string text)
    {
        _submittedText = text;
        _controller = new LogController(_aiServiceMock.Object);
    }

    [Given(@"the AI service is mocked to return a valid extraction JSON")]
    public void GivenTheAiServiceIsMockedToReturnValidExtractionJson()
    {
        const string json =
            "{\"calories\":600,\"protein\":35.0,\"carbs\":70.0,\"fat\":12.0," +
            "\"muscles\":[\"Chest\"]}";

        _aiServiceMock
            .Setup(s => s.GenerateJsonAsync(It.IsAny<string>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(json);
    }

    [When(@"the log parsing endpoint is called")]
    public async Task WhenTheLogParsingEndpointIsCalled()
    {
        _result = await _controller!.Parse(new ParseLogRequest { Text = _submittedText });
    }

    [Then(@"the response should contain 600 calories")]
    public void ThenTheResponseShouldContainCalories()
    {
        var okResult = _result as OkObjectResult;
        var response = okResult!.Value as ParsedLogResponse;

        response.Should().NotBeNull();
        response!.Calories.Should().Be(600);
    }

    [Then(@"the exercised muscles should include ""(.*)""")]
    public void ThenTheExercisedMusclesShouldInclude(string muscle)
    {
        var okResult = _result as OkObjectResult;
        var response = okResult!.Value as ParsedLogResponse;

        response.Should().NotBeNull();
        response!.Muscles.Should().Contain(muscle);
    }
}
