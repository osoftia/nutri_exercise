using FluentAssertions;
using Microsoft.AspNetCore.Mvc;
using NutriExercise.Api.Controllers;
using NutriExercise.Core.DTOs;

namespace NutriExercise.Tests;

public class RagControllerTests
{
    [Fact]
    public void Query_WithValidRequest_ReturnsOkWithRagResponseStructure()
    {
        var request = new RagRequest("Prompt", 0.7, 0.8, "Query");
        var controller = new RagController();

        var result = controller.Query(request);

        var okResult = result.Should().BeOfType<OkObjectResult>().Subject;
        var response = okResult.Value.Should().BeOfType<RagResponse>().Subject;

        response.GeneratedText.Should().NotBeNullOrEmpty();
        response.RetrievedContexts.Should().NotBeNull();
        response.RetrievedContexts.Should().NotBeEmpty();
        response.Telemetry.Should().NotBeNull();
        response.Telemetry.LatencyMs.Should().BeGreaterThanOrEqualTo(0);
        response.Telemetry.PgVectorScores.Should().NotBeNull();
        response.Telemetry.PgVectorScores.Should().NotBeEmpty();
    }

    [Fact]
    public void Query_WithNullRequest_ThrowsArgumentNullException()
    {
        var controller = new RagController();

        var act = () => controller.Query(null!);

        act.Should().Throw<ArgumentNullException>();
    }
}
