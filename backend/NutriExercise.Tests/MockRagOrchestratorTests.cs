using FluentAssertions;
using NutriExercise.Core.DTOs;
using NutriExercise.Infrastructure.Services;

namespace NutriExercise.Tests;

public class MockRagOrchestratorTests
{
    [Fact]
    public async Task ExecuteQueryAsync_ReturnsMockedResponseWithZeroLatency()
    {
        var orchestrator = new MockRagOrchestrator();
        var request = new RagRequest("Prompt", 0.7, 0.8, "Query");

        var response = await orchestrator.ExecuteQueryAsync(request);

        response.GeneratedText.Should().NotBeNullOrEmpty();
        response.RetrievedContexts.Should().NotBeEmpty();
        response.Telemetry.LatencyMs.Should().Be(0);
        response.Telemetry.PgVectorScores.Should().NotBeEmpty();
    }

    [Fact]
    public async Task ExecuteQueryAsync_WithNullRequest_ThrowsArgumentNullException()
    {
        var orchestrator = new MockRagOrchestrator();

        var act = async () => await orchestrator.ExecuteQueryAsync(null!);

        await act.Should().ThrowAsync<ArgumentNullException>();
    }

    [Fact]
    public async Task IngestAsync_ReturnsMockedResponseWithResolvedUser()
    {
        var orchestrator = new MockRagOrchestrator();
        var request = new RagIngestRequest("Title", "Content", "Back");

        var response = await orchestrator.IngestAsync(request, 1);

        response.Title.Should().Be("Title");
        response.BodyZone.Should().Be("Back");
        response.UserId.Should().Be(1);
        response.Id.Should().NotBe(Guid.Empty);
    }

    [Fact]
    public async Task IngestAsync_WithNullRequest_ThrowsArgumentNullException()
    {
        var orchestrator = new MockRagOrchestrator();

        var act = async () => await orchestrator.IngestAsync(null!, 1);

        await act.Should().ThrowAsync<ArgumentNullException>();
    }
}
