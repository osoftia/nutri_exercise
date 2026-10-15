using FluentAssertions;
using Microsoft.AspNetCore.Mvc;
using Moq;
using NutriExercise.Api.Controllers;
using NutriExercise.Core.Configuration;
using NutriExercise.Core.DTOs;
using NutriExercise.Core.Entities;
using NutriExercise.Core.Interfaces;

namespace NutriExercise.Tests;

public class RagControllerTests
{
    private readonly Mock<IRagOrchestrator> _orchestratorMock = new();
    private readonly Mock<IUserRepository> _userRepositoryMock = new();
    private readonly Mock<IRagLogger> _ragLoggerMock = new();

    private RagController CreateController()
    {
        return new RagController(
            _orchestratorMock.Object,
            _userRepositoryMock.Object,
            _ragLoggerMock.Object);
    }

    private void SetupDefaultUser()
    {
        _userRepositoryMock
            .Setup(r => r.EnsureSeedUserAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(new User
            {
                Id = DefaultUser.Id,
                Name = DefaultUser.Name,
                Email = DefaultUser.Email
            });
    }

    [Fact]
    public async Task Query_WithValidRequest_DelegatesToOrchestrator()
    {
        var request = new RagRequest("Prompt", 0.7, 0.8, "Query");
        var expected = new RagResponse(
            "generated",
            new List<string> { "ctx1", "ctx2" },
            new TelemetryData(12, new List<double> { 0.9, 0.8 }));

        SetupDefaultUser();

        _orchestratorMock
            .Setup(o => o.ExecuteQueryAsync(
                request,
                It.IsAny<CancellationToken>()))
            .ReturnsAsync(expected);

        var controller = CreateController();

        var result = await controller.Query(request);

        var okResult = result.Should().BeOfType<OkObjectResult>().Subject;
        okResult.Value.Should().BeSameAs(expected);
        _orchestratorMock.Verify(
            o => o.ExecuteQueryAsync(
                request,
                It.IsAny<CancellationToken>()),
            Times.Once);
    }

    [Fact]
    public async Task Query_WithNullRequest_ThrowsArgumentNullException()
    {
        var controller = CreateController();

        var act = async () => await controller.Query(null!);

        await act.Should().ThrowAsync<ArgumentNullException>();
    }

    [Fact]
    public async Task Query_WithoutUserId_AssociatesDefaultTestUser()
    {
        var request = new RagRequest("Prompt", 0.7, 0.8, "Query");
        var expected = new RagResponse(
            "generated",
            new List<string> { "ctx" },
            new TelemetryData(5, new List<double> { 0.9 }));

        SetupDefaultUser();

        _orchestratorMock
            .Setup(o => o.ExecuteQueryAsync(
                It.IsAny<RagRequest>(),
                It.IsAny<CancellationToken>()))
            .ReturnsAsync(expected);

        var controller = CreateController();

        var result = await controller.Query(request);

        result.Should().BeOfType<OkObjectResult>();
        _userRepositoryMock.Verify(
            r => r.EnsureSeedUserAsync(It.IsAny<CancellationToken>()),
            Times.Once);
    }

    [Fact]
    public async Task Query_WithExplicitUserId_UsesExistingUser()
    {
        var request = new RagRequest("Prompt", 0.7, 0.8, "Query", 42);
        var expected = new RagResponse(
            "generated",
            new List<string> { "ctx" },
            new TelemetryData(5, new List<double> { 0.9 }));

        _userRepositoryMock
            .Setup(r => r.GetByIdAsync(42, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new User { Id = 42, Name = "Other", Email = "o@x.io" });

        _orchestratorMock
            .Setup(o => o.ExecuteQueryAsync(
                It.IsAny<RagRequest>(),
                It.IsAny<CancellationToken>()))
            .ReturnsAsync(expected);

        var controller = CreateController();

        var result = await controller.Query(request);

        result.Should().BeOfType<OkObjectResult>();
        _userRepositoryMock.Verify(
            r => r.GetByIdAsync(42, It.IsAny<CancellationToken>()),
            Times.Once);
        _userRepositoryMock.Verify(
            r => r.EnsureSeedUserAsync(It.IsAny<CancellationToken>()),
            Times.Never);
    }

    [Fact]
    public async Task Query_OnSuccess_LogsInfoWithRagTag()
    {
        var request = new RagRequest("Prompt", 0.7, 0.8, "Query");
        var expected = new RagResponse(
            "generated",
            new List<string> { "ctx" },
            new TelemetryData(5, new List<double> { 0.9 }));

        SetupDefaultUser();

        _orchestratorMock
            .Setup(o => o.ExecuteQueryAsync(
                It.IsAny<RagRequest>(),
                It.IsAny<CancellationToken>()))
            .ReturnsAsync(expected);

        var controller = CreateController();

        await controller.Query(request);

        _ragLoggerMock.Verify(
            l => l.LogInfo(
                It.IsAny<string>(),
                It.IsAny<object[]>()),
            Times.Once);
    }

    [Fact]
    public async Task Ingest_WithValidRequest_DelegatesToOrchestratorAndReturnsOk()
    {
        var request = new RagIngestRequest("Title", "Content", "Chest");
        var expected = new RagIngestResponse(
            Guid.NewGuid(),
            "Title",
            "Chest",
            DefaultUser.Id,
            768,
            "Document ingested successfully.");

        SetupDefaultUser();

        _orchestratorMock
            .Setup(o => o.IngestAsync(
                request,
                DefaultUser.Id,
                It.IsAny<CancellationToken>()))
            .ReturnsAsync(expected);

        var controller = CreateController();

        var result = await controller.Ingest(request);

        var okResult = result.Should().BeOfType<OkObjectResult>().Subject;
        okResult.Value.Should().BeSameAs(expected);
        _orchestratorMock.Verify(
            o => o.IngestAsync(
                request,
                DefaultUser.Id,
                It.IsAny<CancellationToken>()),
            Times.Once);
    }

    [Fact]
    public async Task Ingest_WithoutUserId_AssociatesDefaultTestUser()
    {
        var request = new RagIngestRequest("Title", "Content", "Legs");
        var expected = new RagIngestResponse(
            Guid.NewGuid(),
            "Title",
            "Legs",
            DefaultUser.Id,
            768,
            "Document ingested successfully.");

        SetupDefaultUser();

        _orchestratorMock
            .Setup(o => o.IngestAsync(
                It.IsAny<RagIngestRequest>(),
                It.IsAny<int>(),
                It.IsAny<CancellationToken>()))
            .ReturnsAsync(expected);

        var controller = CreateController();

        var result = await controller.Ingest(request);

        result.Should().BeOfType<OkObjectResult>();
        _userRepositoryMock.Verify(
            r => r.EnsureSeedUserAsync(It.IsAny<CancellationToken>()),
            Times.Once);
    }

    [Fact]
    public async Task Ingest_WithExplicitUserId_UsesExistingUser()
    {
        var request = new RagIngestRequest("Title", "Content", "Back", 42);
        var expected = new RagIngestResponse(
            Guid.NewGuid(),
            "Title",
            "Back",
            42,
            768,
            "Document ingested successfully.");

        _userRepositoryMock
            .Setup(r => r.GetByIdAsync(42, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new User { Id = 42, Name = "Other", Email = "o@x.io" });

        _orchestratorMock
            .Setup(o => o.IngestAsync(
                It.IsAny<RagIngestRequest>(),
                It.IsAny<int>(),
                It.IsAny<CancellationToken>()))
            .ReturnsAsync(expected);

        var controller = CreateController();

        var result = await controller.Ingest(request);

        result.Should().BeOfType<OkObjectResult>();
        _orchestratorMock.Verify(
            o => o.IngestAsync(
                request,
                42,
                It.IsAny<CancellationToken>()),
            Times.Once);
        _userRepositoryMock.Verify(
            r => r.EnsureSeedUserAsync(It.IsAny<CancellationToken>()),
            Times.Never);
    }

    [Theory]
    [InlineData("", "Content", "Chest")]
    [InlineData("Title", "", "Chest")]
    [InlineData("Title", "Content", "")]
    public async Task Ingest_WithMissingFields_ReturnsBadRequest(
        string title,
        string content,
        string bodyZone)
    {
        var request = new RagIngestRequest(title, content, bodyZone);
        var controller = CreateController();

        var result = await controller.Ingest(request);

        result.Should().BeOfType<BadRequestObjectResult>();
        _orchestratorMock.Verify(
            o => o.IngestAsync(
                It.IsAny<RagIngestRequest>(),
                It.IsAny<int>(),
                It.IsAny<CancellationToken>()),
            Times.Never);
    }

    [Fact]
    public async Task Ingest_OnSuccess_LogsInfoWithRagTag()
    {
        var request = new RagIngestRequest("Title", "Content", "Core");
        var expected = new RagIngestResponse(
            Guid.NewGuid(),
            "Title",
            "Core",
            DefaultUser.Id,
            768,
            "Document ingested successfully.");

        SetupDefaultUser();

        _orchestratorMock
            .Setup(o => o.IngestAsync(
                It.IsAny<RagIngestRequest>(),
                It.IsAny<int>(),
                It.IsAny<CancellationToken>()))
            .ReturnsAsync(expected);

        var controller = CreateController();

        await controller.Ingest(request);

        _ragLoggerMock.Verify(
            l => l.LogInfo(
                It.IsAny<string>(),
                It.IsAny<object[]>()),
            Times.Once);
    }
}
