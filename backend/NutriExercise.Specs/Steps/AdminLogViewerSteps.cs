using System.Globalization;
using System.Text.Json;
using FluentAssertions;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging.Abstractions;
using NutriExercise.Api.Controllers;
using NutriExercise.Core.DTOs;
using NutriExercise.Infrastructure.Services;
using Reqnroll;

namespace NutriExercise.Specs.Steps;

[Binding]
public class AdminLogViewerSteps : IDisposable
{
    private readonly string _directory;
    private AdminLogsController? _controller;
    private PagedLogResponse? _response;

    public AdminLogViewerSteps()
    {
        _directory = Path.Combine(
            Path.GetTempPath(),
            "nutri-spec-logs-" + Guid.NewGuid().ToString("N"));
        Directory.CreateDirectory(_directory);
    }

    [Given(@"the log fixtures:")]
    public void GivenTheLogFixtures(Table table)
    {
        ArgumentNullException.ThrowIfNull(table);

        foreach (var row in table.Rows)
        {
            var line = JsonSerializer.Serialize(new
            {
                Timestamp = row["timestamp"],
                Level = row["level"],
                RenderedMessage = row["message"]
            });

            File.AppendAllLines(Path.Combine(_directory, row["file"]), new[] { line });
        }

        _controller = new AdminLogsController(
            new FileLogReaderService(_directory, NullLogger<FileLogReaderService>.Instance));
    }

    [When(@"I request logs from ""(.*)"" to ""(.*)"" filtered by level ""(.*)""")]
    public Task WhenIRequestLogsInRange(string start, string end, string level) =>
        InvokeAsync(new LogQuery(
            Parse(start),
            Parse(end),
            LogLevel: level));

    [When(@"I request logs filtered by tag ""(.*)""")]
    public Task WhenIRequestLogsByTag(string tag) =>
        InvokeAsync(new LogQuery(Tag: tag));

    [When(@"I request all logs")]
    public Task WhenIRequestAllLogs() =>
        InvokeAsync(new LogQuery());

    [When(@"I request page (.*) with page size (.*)")]
    public Task WhenIRequestPage(int page, int size) =>
        InvokeAsync(new LogQuery(PageNumber: page, PageSize: size));

    [Then(@"the response should contain (.*) log entries")]
    public void ThenTheResponseContains(int count)
    {
        Response().Items.Should().HaveCount(count);
    }

    [Then(@"every entry in the response should have level ""(.*)""")]
    public void ThenEveryEntryHasLevel(string level)
    {
        Response().Items.Should().OnlyContain(entry => entry.Level == level);
    }

    [Then(@"the first entry message should contain ""(.*)""")]
    public void ThenTheFirstMessageContains(string expected)
    {
        Response().Items.Should().NotBeEmpty();
        Response().Items[0].Message.Should().Contain(expected);
    }

    [Then(@"the first entry timestamp should be ""(.*)""")]
    public void ThenTheFirstTimestampIs(string expected)
    {
        Response().Items.Should().NotBeEmpty();
        Response().Items[0].Timestamp.Should().Be(Parse(expected));
    }

    public void Dispose()
    {
        if (Directory.Exists(_directory))
        {
            Directory.Delete(_directory, recursive: true);
        }

        GC.SuppressFinalize(this);
    }

    private async Task InvokeAsync(LogQuery query)
    {
        var result = await _controller!.GetLogs(
            query.StartDate,
            query.EndDate,
            query.LogLevel,
            query.Tag,
            query.PageNumber,
            query.PageSize);

        _response = (result as OkObjectResult)?.Value as PagedLogResponse;
    }

    private PagedLogResponse Response()
    {
        _response.Should().NotBeNull();

        return _response!;
    }

    private static DateTimeOffset Parse(string value) =>
        DateTimeOffset.Parse(value, CultureInfo.InvariantCulture, DateTimeStyles.RoundtripKind);
}
