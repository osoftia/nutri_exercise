using FluentAssertions;
using Moq;
using NutriExercise.Core.Entities;
using NutriExercise.Core.Interfaces;
using NutriExercise.Infrastructure.Services;
using Pgvector;

namespace NutriExercise.Tests;

public class VectorSearchServiceTests
{
    private readonly Mock<IAiService> _aiServiceMock = new();
    private readonly Mock<IResearchDocumentRepository> _repositoryMock = new();
    private readonly Mock<IRagLogger> _ragLoggerMock = new();

    private VectorSearchService CreateService()
    {
        return new VectorSearchService(
            _aiServiceMock.Object,
            _repositoryMock.Object,
            _ragLoggerMock.Object);
    }

    [Fact]
    public async Task SearchWithScoresAsync_FiltersByThresholdAndReturnsScores()
    {
        const string query = "hypertrophy";

        _aiServiceMock
            .Setup(s => s.GenerateEmbeddingAsync(
                query,
                It.IsAny<CancellationToken>()))
            .ReturnsAsync(new float[] { 1f, 0f });

        var documents = new List<ResearchDocument>
        {
            new() { Content = "identical", Embedding = new Vector(new float[] { 1f, 0f }) },
            new() { Content = "orthogonal", Embedding = new Vector(new float[] { 0f, 1f }) }
        };

        _repositoryMock
            .Setup(r => r.SearchSimilarDocumentsAsync(
                It.IsAny<float[]>(),
                It.IsAny<int>(),
                It.IsAny<CancellationToken>()))
            .ReturnsAsync(documents);

        var service = CreateService();

        var result = await service.SearchWithScoresAsync(query, 0.5);

        result.Contexts.Should().ContainSingle().Which.Should().Be("identical");
        result.Scores.Should().ContainSingle();
        result.Scores[0].Should().BeApproximately(1.0, 1e-9);
    }

    [Fact]
    public async Task SearchWithScoresAsync_WithBlankQuery_ReturnsEmpty()
    {
        var service = CreateService();

        var result = await service.SearchWithScoresAsync("   ", 0.5);

        result.Contexts.Should().BeEmpty();
        result.Scores.Should().BeEmpty();
        _aiServiceMock.Verify(
            s => s.GenerateEmbeddingAsync(
                It.IsAny<string>(),
                It.IsAny<CancellationToken>()),
            Times.Never);
    }

    [Fact]
    public async Task SearchWithScoresAsync_WhenRepositoryFails_LogsErrorAndRethrows()
    {
        _aiServiceMock
            .Setup(s => s.GenerateEmbeddingAsync(
                It.IsAny<string>(),
                It.IsAny<CancellationToken>()))
            .ReturnsAsync(new float[] { 1f, 0f });

        _repositoryMock
            .Setup(r => r.SearchSimilarDocumentsAsync(
                It.IsAny<float[]>(),
                It.IsAny<int>(),
                It.IsAny<CancellationToken>()))
            .ThrowsAsync(new InvalidOperationException("pgvector offline"));

        var service = CreateService();

        var act = async () => await service.SearchWithScoresAsync("query", 0.5);

        await act.Should().ThrowAsync<InvalidOperationException>();

        _ragLoggerMock.Verify(
            l => l.LogError(
                It.IsAny<Exception>(),
                It.IsAny<string>(),
                It.IsAny<object[]>()),
            Times.Once);
    }
}
