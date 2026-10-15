using FluentAssertions;
using Moq;
using NutriExercise.Core.Configuration;
using NutriExercise.Core.DTOs;
using NutriExercise.Core.Entities;
using NutriExercise.Core.Interfaces;
using NutriExercise.Infrastructure.Services;

namespace NutriExercise.Tests;

public class RealRagOrchestratorTests
{
    private readonly Mock<IVectorSearchService> _vectorSearchMock = new();
    private readonly Mock<IAiModelService> _aiModelMock = new();
    private readonly Mock<IAiService> _aiServiceMock = new();
    private readonly Mock<IResearchDocumentRepository> _documentRepositoryMock = new();
    private readonly Mock<IRagLogger> _ragLoggerMock = new();

    private RealRagOrchestrator CreateOrchestrator()
    {
        return new RealRagOrchestrator(
            _vectorSearchMock.Object,
            _aiModelMock.Object,
            _aiServiceMock.Object,
            _documentRepositoryMock.Object,
            _ragLoggerMock.Object);
    }

    [Fact]
    public async Task ExecuteQueryAsync_UsesSearchResultsAndAiModel()
    {
        var request = new RagRequest("System", 0.5, 0.8, "Query");
        var contexts = new List<string> { "ctx1", "ctx2" };
        var scores = new List<double> { 0.95, 0.9 };

        _vectorSearchMock
            .Setup(s => s.SearchWithScoresAsync(
                request.Query,
                request.SimilarityThreshold,
                It.IsAny<CancellationToken>()))
            .ReturnsAsync(new VectorSearchResult(contexts, scores));

        _aiModelMock
            .Setup(s => s.GenerateAsync(
                request.SystemPrompt,
                request.Query,
                It.IsAny<IReadOnlyList<string>>(),
                request.Temperature,
                It.IsAny<CancellationToken>()))
            .ReturnsAsync("real answer");

        var orchestrator = CreateOrchestrator();

        var response = await orchestrator.ExecuteQueryAsync(request);

        response.GeneratedText.Should().Be("real answer");
        response.RetrievedContexts.Should().BeEquivalentTo(contexts);
        response.Telemetry.PgVectorScores.Should().BeEquivalentTo(scores);
        response.Telemetry.LatencyMs.Should().BeGreaterThanOrEqualTo(0);

        _vectorSearchMock.Verify(
            s => s.SearchWithScoresAsync(
                request.Query,
                request.SimilarityThreshold,
                It.IsAny<CancellationToken>()),
            Times.Once);

        _aiModelMock.Verify(
            s => s.GenerateAsync(
                request.SystemPrompt,
                request.Query,
                It.IsAny<IReadOnlyList<string>>(),
                request.Temperature,
                It.IsAny<CancellationToken>()),
            Times.Once);
    }

    [Fact]
    public async Task ExecuteQueryAsync_WithNullRequest_ThrowsArgumentNullException()
    {
        var orchestrator = CreateOrchestrator();

        var act = async () => await orchestrator.ExecuteQueryAsync(null!);

        await act.Should().ThrowAsync<ArgumentNullException>();
    }

    [Fact]
    public async Task ExecuteQueryAsync_WhenSearchFails_LogsErrorAndRethrows()
    {
        var request = new RagRequest("System", 0.5, 0.8, "Query");

        _vectorSearchMock
            .Setup(s => s.SearchWithScoresAsync(
                It.IsAny<string>(),
                It.IsAny<double>(),
                It.IsAny<CancellationToken>()))
            .ThrowsAsync(new InvalidOperationException("pgvector failure"));

        var orchestrator = CreateOrchestrator();

        var act = async () => await orchestrator.ExecuteQueryAsync(request);

        await act.Should().ThrowAsync<InvalidOperationException>();

        _ragLoggerMock.Verify(
            l => l.LogError(
                It.IsAny<Exception>(),
                It.IsAny<string>(),
                It.IsAny<object[]>()),
            Times.Once);
    }

    [Fact]
    public async Task ExecuteQueryAsync_OnSuccess_LogsThroughputTelemetry()
    {
        var request = new RagRequest("System", 0.5, 0.8, "Query");

        _vectorSearchMock
            .Setup(s => s.SearchWithScoresAsync(
                It.IsAny<string>(),
                It.IsAny<double>(),
                It.IsAny<CancellationToken>()))
            .ReturnsAsync(new VectorSearchResult(
                new List<string> { "ctx" },
                new List<double> { 0.9 }));

        _aiModelMock
            .Setup(s => s.GenerateAsync(
                It.IsAny<string>(),
                It.IsAny<string>(),
                It.IsAny<IReadOnlyList<string>>(),
                It.IsAny<double>(),
                It.IsAny<CancellationToken>()))
            .ReturnsAsync("answer");

        var orchestrator = CreateOrchestrator();

        await orchestrator.ExecuteQueryAsync(request);

        _ragLoggerMock.Verify(
            l => l.LogInfo(
                It.IsAny<string>(),
                It.IsAny<object[]>()),
            Times.Once);
    }

    [Fact]
    public async Task IngestAsync_WithValidRequest_EmbedsAndPersistsOwnedDocument()
    {
        var request = new RagIngestRequest("Progressive Overload", "Train hard.", "Chest");
        var embedding = new float[] { 0.1f, 0.2f, 0.3f };
        ResearchDocument? persisted = null;

        _aiServiceMock
            .Setup(s => s.GenerateEmbeddingAsync(request.Content, It.IsAny<CancellationToken>()))
            .ReturnsAsync(embedding);

        _documentRepositoryMock
            .Setup(r => r.AddDocumentAsync(
                It.IsAny<ResearchDocument>(),
                It.IsAny<CancellationToken>()))
            .Callback<ResearchDocument, CancellationToken>((document, _) => persisted = document)
            .Returns(Task.CompletedTask);

        var orchestrator = CreateOrchestrator();

        var response = await orchestrator.IngestAsync(request, DefaultUser.Id);

        response.UserId.Should().Be(DefaultUser.Id);
        response.BodyZone.Should().Be("Chest");
        response.Dimensions.Should().Be(3);
        response.Id.Should().NotBe(Guid.Empty);

        persisted.Should().NotBeNull();
        persisted!.UserId.Should().Be(DefaultUser.Id);
        persisted.BodyZone.Should().Be("Chest");
        persisted.Embedding.Should().NotBeNull();

        _ragLoggerMock.Verify(
            l => l.LogInfo(
                It.IsAny<string>(),
                It.IsAny<object[]>()),
            Times.Once);
    }

    [Fact]
    public async Task IngestAsync_WhenEmbeddingIsEmpty_LogsErrorAndThrows()
    {
        var request = new RagIngestRequest("Title", "Content", "Legs");

        _aiServiceMock
            .Setup(s => s.GenerateEmbeddingAsync(
                It.IsAny<string>(),
                It.IsAny<CancellationToken>()))
            .ReturnsAsync(Array.Empty<float>());

        var orchestrator = CreateOrchestrator();

        var act = async () => await orchestrator.IngestAsync(request, DefaultUser.Id);

        await act.Should().ThrowAsync<InvalidOperationException>();

        _documentRepositoryMock.Verify(
            r => r.AddDocumentAsync(
                It.IsAny<ResearchDocument>(),
                It.IsAny<CancellationToken>()),
            Times.Never);

        _ragLoggerMock.Verify(
            l => l.LogError(
                It.IsAny<Exception>(),
                It.IsAny<string>(),
                It.IsAny<object[]>()),
            Times.Once);
    }

    [Fact]
    public async Task IngestAsync_WithNullRequest_ThrowsArgumentNullException()
    {
        var orchestrator = CreateOrchestrator();

        var act = async () => await orchestrator.IngestAsync(null!, DefaultUser.Id);

        await act.Should().ThrowAsync<ArgumentNullException>();
    }
}
