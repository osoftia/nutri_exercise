using FluentAssertions;
using Microsoft.AspNetCore.Mvc;
using Moq;
using NutriExercise.Api.Controllers;
using NutriExercise.Core.DTOs;
using NutriExercise.Core.Interfaces;

namespace NutriExercise.Tests;

public class HealthSyncControllerTests
{
    private readonly Mock<IHealthDataService> _serviceMock = new();

    private HealthSyncController CreateController() => new(_serviceMock.Object);

    [Fact]
    public async Task SyncMetrics_WithValidRequest_DelegatesToServiceAndReturnsOk()
    {
        var request = new HealthMetricsSyncRequest(
            new[] { new HealthMetricDto("steps", 8500, "count", DateTimeOffset.UtcNow) });
        var expected = new HealthSyncResponse(1, 1, 0, Array.Empty<HealthMetricSyncResult>());

        _serviceMock
            .Setup(service => service.SyncAsync(request, It.IsAny<CancellationToken>()))
            .ReturnsAsync(expected);

        var controller = CreateController();

        var result = await controller.SyncMetrics(request);

        var okResult = result.Should().BeOfType<OkObjectResult>().Subject;
        okResult.Value.Should().BeSameAs(expected);
    }

    [Fact]
    public async Task SyncMetrics_WithNoMetrics_ReturnsBadRequest()
    {
        var request = new HealthMetricsSyncRequest(Array.Empty<HealthMetricDto>());
        var controller = CreateController();

        var result = await controller.SyncMetrics(request);

        result.Should().BeOfType<BadRequestObjectResult>();
        _serviceMock.Verify(
            service => service.SyncAsync(It.IsAny<HealthMetricsSyncRequest>(), It.IsAny<CancellationToken>()),
            Times.Never);
    }

    [Fact]
    public void Constructor_WithNullService_Throws()
    {
        var act = () => new HealthSyncController(null!);

        act.Should().Throw<ArgumentNullException>();
    }
}
