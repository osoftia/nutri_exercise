using FluentAssertions;
using Microsoft.AspNetCore.Mvc;
using Moq;
using NutriExercise.Api.Controllers;
using NutriExercise.Core.DTOs;
using NutriExercise.Core.Interfaces;

namespace NutriExercise.Tests;

public class AdminLogsControllerTests
{
    private readonly Mock<ILogReaderService> _serviceMock = new();

    [Fact]
    public async Task GetLogs_MapsQueryParametersAndReturnsOk()
    {
        var expected = new PagedLogResponse(Array.Empty<LogEntryDto>(), 2, 25, 0);
        LogQuery? captured = null;

        _serviceMock
            .Setup(service => service.GetLogsAsync(
                It.IsAny<LogQuery>(),
                It.IsAny<CancellationToken>()))
            .Callback<LogQuery, CancellationToken>((query, _) => captured = query)
            .ReturnsAsync(expected);

        var controller = new AdminLogsController(_serviceMock.Object);

        var result = await controller.GetLogs(
            DateTimeOffset.Parse("2026-09-30T00:00:00+00:00"),
            DateTimeOffset.Parse("2026-10-01T23:59:59+00:00"),
            "Error",
            "[RAG-ERROR]",
            2,
            25);

        result.Should().BeOfType<OkObjectResult>();

        captured.Should().NotBeNull();
        captured!.LogLevel.Should().Be("Error");
        captured.Tag.Should().Be("[RAG-ERROR]");
        captured.PageNumber.Should().Be(2);
        captured.PageSize.Should().Be(25);
    }

    [Fact]
    public void Constructor_WithNullService_Throws()
    {
        var act = () => new AdminLogsController(null!);

        act.Should().Throw<ArgumentNullException>();
    }
}
