using FluentAssertions;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging.Abstractions;
using NutriExercise.Core.DTOs;
using NutriExercise.Infrastructure.Data;
using NutriExercise.Infrastructure.Services;

namespace NutriExercise.Tests;

public class HealthDataServiceTests
{
    private static AppDbContext CreateContext(string name)
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(name)
            .Options;

        return new AppDbContext(options);
    }

    private static HealthDataService CreateService(AppDbContext context) =>
        new(context, NullLogger<HealthDataService>.Instance);

    private static HealthMetricsSyncRequest Request(params HealthMetricDto[] metrics) =>
        new(metrics, UserId: 1);

    [Fact]
    public async Task SyncAsync_WithNewMetrics_InsertsAndPersistsThem()
    {
        await using var context = CreateContext(nameof(SyncAsync_WithNewMetrics_InsertsAndPersistsThem));
        var service = CreateService(context);

        var response = await service.SyncAsync(Request(
            new HealthMetricDto("steps", 8500, "count", DateTimeOffset.Parse("2026-10-01T08:00:00+00:00")),
            new HealthMetricDto("sleep_duration", 7.5, "hours", DateTimeOffset.Parse("2026-10-01T07:00:00+00:00"))));

        response.Received.Should().Be(2);
        response.Inserted.Should().Be(2);
        response.Updated.Should().Be(0);
        context.HealthMetrics.Should().HaveCount(2);
    }

    [Fact]
    public async Task SyncAsync_WithExistingMetric_UpdatesInsteadOfInserting()
    {
        await using var context = CreateContext(nameof(SyncAsync_WithExistingMetric_UpdatesInsteadOfInserting));
        var service = CreateService(context);
        var timestamp = DateTimeOffset.Parse("2026-10-01T08:00:00+00:00");

        await service.SyncAsync(Request(new HealthMetricDto("steps", 8500, "count", timestamp)));
        var response = await service.SyncAsync(Request(new HealthMetricDto("steps", 9000, "count", timestamp)));

        response.Received.Should().Be(1);
        response.Inserted.Should().Be(0);
        response.Updated.Should().Be(1);
        context.HealthMetrics.Should().ContainSingle();

        var stored = await context.HealthMetrics.SingleAsync();
        stored.Value.Should().Be(9000);
    }

    [Fact]
    public async Task SyncAsync_WithDuplicateInSameBatch_DoesNotDuplicateRecords()
    {
        await using var context = CreateContext(nameof(SyncAsync_WithDuplicateInSameBatch_DoesNotDuplicateRecords));
        var service = CreateService(context);
        var timestamp = DateTimeOffset.Parse("2026-10-01T08:00:00+00:00");

        await service.SyncAsync(Request(
            new HealthMetricDto("steps", 8500, "count", timestamp),
            new HealthMetricDto("steps", 9000, "count", timestamp)));

        context.HealthMetrics.Should().ContainSingle();
        (await context.HealthMetrics.SingleAsync()).Value.Should().Be(9000);
    }

    [Fact]
    public async Task SyncAsync_DeduplicatesByMetricTypeAndTimestamp()
    {
        await using var context = CreateContext(nameof(SyncAsync_DeduplicatesByMetricTypeAndTimestamp));
        var service = CreateService(context);

        await service.SyncAsync(Request(
            new HealthMetricDto("steps", 1000, "count", DateTimeOffset.Parse("2026-10-01T08:00:00+00:00")),
            new HealthMetricDto("steps", 2000, "count", DateTimeOffset.Parse("2026-10-01T09:00:00+00:00"))));

        context.HealthMetrics.Should().HaveCount(2);
    }

    [Fact]
    public async Task SyncAsync_AssociatesMetricsWithTheRequestedUser()
    {
        await using var context = CreateContext(nameof(SyncAsync_AssociatesMetricsWithTheRequestedUser));
        var service = CreateService(context);

        await service.SyncAsync(new HealthMetricsSyncRequest(
            new[] { new HealthMetricDto("heart_rate", 72, "bpm", DateTimeOffset.Parse("2026-10-01T08:00:00+00:00")) },
            UserId: 42));

        (await context.HealthMetrics.SingleAsync()).UserId.Should().Be(42);
    }

    [Fact]
    public async Task SyncAsync_WithEmptyMetrics_ReturnsZeroedResponse()
    {
        await using var context = CreateContext(nameof(SyncAsync_WithEmptyMetrics_ReturnsZeroedResponse));
        var service = CreateService(context);

        var response = await service.SyncAsync(new HealthMetricsSyncRequest(Array.Empty<HealthMetricDto>()));

        response.Received.Should().Be(0);
        response.Inserted.Should().Be(0);
        response.Updated.Should().Be(0);
        context.HealthMetrics.Should().BeEmpty();
    }

    [Fact]
    public async Task SyncAsync_WithNullRequest_ThrowsArgumentNullException()
    {
        await using var context = CreateContext(nameof(SyncAsync_WithNullRequest_ThrowsArgumentNullException));
        var service = CreateService(context);

        var act = async () => await service.SyncAsync(null!);

        await act.Should().ThrowAsync<ArgumentNullException>();
    }
}
