using System.Globalization;
using FluentAssertions;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging.Abstractions;
using NutriExercise.Api.Controllers;
using NutriExercise.Core.DTOs;
using NutriExercise.Infrastructure.Data;
using NutriExercise.Infrastructure.Services;
using Reqnroll;

namespace NutriExercise.Specs.Steps;

[Binding]
public class HealthDataSyncSteps : IDisposable
{
    private readonly string _databaseName;
    private AppDbContext? _context;
    private HealthSyncController? _controller;
    private HealthSyncResponse? _response;

    public HealthDataSyncSteps()
    {
        _databaseName = "health-sync-" + Guid.NewGuid().ToString("N");
    }

    [Given(@"the health sync API is running with an empty store")]
    public void GivenTheHealthSyncApiIsRunningWithAnEmptyStore()
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(_databaseName)
            .Options;

        _context = new AppDbContext(options);
        _controller = new HealthSyncController(
            new HealthDataService(_context, NullLogger<HealthDataService>.Instance));
    }

    [Given(@"the mobile app has already synced ""(.*)"" with value (.*) at ""(.*)""")]
    public Task GivenTheMobileAppHasAlreadySynced(string metricType, double value, string timestamp) =>
        SyncAsync(SingleMetric(metricType, value, "count", timestamp));

    [When(@"the mobile app syncs the following metrics:")]
    public async Task WhenTheMobileAppSyncsTheFollowingMetrics(Table table)
    {
        ArgumentNullException.ThrowIfNull(table);

        var metrics = table.Rows
            .Select(row => new HealthMetricDto(
                row["metricType"],
                double.Parse(row["value"], CultureInfo.InvariantCulture),
                row["unit"],
                Parse(row["timestamp"])))
            .ToList();

        await SyncAsync(new HealthMetricsSyncRequest(metrics, UserId: 1));
    }

    [When(@"the mobile app retries syncing ""(.*)"" with value (.*) at ""(.*)""")]
    public Task WhenTheMobileAppRetriesSyncing(string metricType, double value, string timestamp) =>
        SyncAsync(SingleMetric(metricType, value, "count", timestamp));

    [Then(@"the sync response should report (.*) received, (.*) inserted and (.*) updated")]
    public void ThenTheSyncResponseShouldReport(int received, int inserted, int updated)
    {
        Response().Received.Should().Be(received);
        Response().Inserted.Should().Be(inserted);
        Response().Updated.Should().Be(updated);
    }

    [Then(@"the store should contain (.*) health metrics")]
    public async Task ThenTheStoreShouldContain(int count)
    {
        var stored = await _context!.HealthMetrics.CountAsync();

        stored.Should().Be(count);
    }

    [Then(@"the ""(.*)"" metric should have value (.*)")]
    public async Task ThenTheMetricShouldHaveValue(string metricType, double value)
    {
        var stored = await _context!.HealthMetrics
            .SingleAsync(metric => metric.MetricType == metricType);

        stored.Value.Should().Be(value);
    }

    public void Dispose()
    {
        if (_context is not null)
        {
            _context.Dispose();
        }

        GC.SuppressFinalize(this);
    }

    private static HealthMetricsSyncRequest SingleMetric(
        string metricType,
        double value,
        string unit,
        string timestamp) =>
        new(
            new[] { new HealthMetricDto(metricType, value, unit, Parse(timestamp)) },
            UserId: 1);

    private async Task SyncAsync(HealthMetricsSyncRequest request)
    {
        var result = await _controller!.SyncMetrics(request);

        _response = (result as OkObjectResult)?.Value as HealthSyncResponse;
    }

    private HealthSyncResponse Response()
    {
        _response.Should().NotBeNull();

        return _response!;
    }

    private static DateTimeOffset Parse(string value) =>
        DateTimeOffset.Parse(value, CultureInfo.InvariantCulture, DateTimeStyles.RoundtripKind);
}
