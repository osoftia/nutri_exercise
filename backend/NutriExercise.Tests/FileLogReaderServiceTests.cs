using FluentAssertions;
using Microsoft.Extensions.Logging.Abstractions;
using NutriExercise.Core.DTOs;
using NutriExercise.Infrastructure.Services;

namespace NutriExercise.Tests;

public class FileLogReaderServiceTests : IDisposable
{
    private readonly string _directory;

    public FileLogReaderServiceTests()
    {
        _directory = Path.Combine(
            Path.GetTempPath(),
            "nutri-logs-" + Guid.NewGuid().ToString("N"));
        Directory.CreateDirectory(_directory);
    }

    public void Dispose()
    {
        if (Directory.Exists(_directory))
        {
            Directory.Delete(_directory, recursive: true);
        }

        GC.SuppressFinalize(this);
    }

    [Fact]
    public async Task GetLogsAsync_ReturnsEntriesNewestFirst()
    {
        WriteLog(
            "nutriexercise-20260930.json",
            ("2026-09-30T08:00:00+00:00", "Information", "[RAG-INFO]: old"),
            ("2026-09-30T09:15:00+00:00", "Error", "[RAG-ERROR]: older"));
        WriteLog(
            "nutriexercise-20261001.json",
            ("2026-10-01T10:00:00+00:00", "Error", "[HTTP-ERROR]: mid"),
            ("2026-10-01T11:30:00+00:00", "Information", "[RAG-INFO]: newest"));

        var response = await CreateService().GetLogsAsync(new LogQuery(PageSize: 10));

        response.TotalCount.Should().Be(4);
        response.Items[0].Message.Should().Be("[RAG-INFO]: newest");
        response.Items[3].Message.Should().Be("[RAG-INFO]: old");
    }

    [Fact]
    public async Task GetLogsAsync_FiltersByLevel()
    {
        WriteLog(
            "nutriexercise-20261001.json",
            ("2026-10-01T10:00:00+00:00", "Error", "[HTTP-ERROR]: boom"),
            ("2026-10-01T11:00:00+00:00", "Information", "[RAG-INFO]: fine"));

        var response = await CreateService().GetLogsAsync(new LogQuery(LogLevel: "error"));

        response.TotalCount.Should().Be(1);
        response.Items[0].Level.Should().Be("Error");
    }

    [Fact]
    public async Task GetLogsAsync_FiltersByDateRange()
    {
        WriteLog(
            "nutriexercise-20260930.json",
            ("2026-09-30T23:59:00+00:00", "Error", "[HTTP-ERROR]: before"),
            ("2026-10-01T10:00:00+00:00", "Error", "[HTTP-ERROR]: inside"),
            ("2026-10-02T10:00:00+00:00", "Error", "[HTTP-ERROR]: after"));

        var response = await CreateService().GetLogsAsync(new LogQuery(
            StartDate: DateTimeOffset.Parse("2026-10-01T00:00:00+00:00"),
            EndDate: DateTimeOffset.Parse("2026-10-01T23:59:59+00:00")));

        response.TotalCount.Should().Be(1);
        response.Items[0].Message.Should().Be("[HTTP-ERROR]: inside");
    }

    [Fact]
    public async Task GetLogsAsync_FiltersByTag()
    {
        WriteLog(
            "nutriexercise-20261001.json",
            ("2026-10-01T10:00:00+00:00", "Error", "[RAG-ERROR]: vector failed"),
            ("2026-10-01T11:00:00+00:00", "Error", "[HTTP-ERROR]: ollama failed"));

        var response = await CreateService().GetLogsAsync(new LogQuery(Tag: "[RAG-ERROR]"));

        response.TotalCount.Should().Be(1);
        response.Items[0].Message.Should().Contain("[RAG-ERROR]");
    }

    [Fact]
    public async Task GetLogsAsync_PaginatesNewestFirst()
    {
        WriteLog(
            "nutriexercise-20261001.json",
            ("2026-10-01T09:00:00+00:00", "Information", "entry-one"),
            ("2026-10-01T10:00:00+00:00", "Information", "entry-two"),
            ("2026-10-01T11:00:00+00:00", "Information", "entry-three"),
            ("2026-10-01T12:00:00+00:00", "Information", "entry-four"));

        var response = await CreateService().GetLogsAsync(new LogQuery(PageNumber: 2, PageSize: 2));

        response.TotalCount.Should().Be(4);
        response.PageNumber.Should().Be(2);
        response.Items.Should().HaveCount(2);
        response.Items[0].Message.Should().Be("entry-two");
        response.Items[1].Message.Should().Be("entry-one");
    }

    [Fact]
    public async Task GetLogsAsync_IgnoresMalformedLines()
    {
        var path = Path.Combine(_directory, "nutriexercise-20261001.json");
        File.WriteAllLines(path, new[]
        {
            "not-json",
            "{\"Timestamp\":\"2026-10-01T10:00:00+00:00\",\"Level\":\"Error\",\"RenderedMessage\":\"valid\"}",
            "{ broken"
        });

        var response = await CreateService().GetLogsAsync(new LogQuery());

        response.TotalCount.Should().Be(1);
        response.Items[0].Message.Should().Be("valid");
    }

    [Fact]
    public async Task GetLogsAsync_ClampsPageSizeToMaximum()
    {
        WriteLog("nutriexercise-20261001.json", ("2026-10-01T10:00:00+00:00", "Information", "one"));

        var response = await CreateService(maxPageSize: 5)
            .GetLogsAsync(new LogQuery(PageSize: 1000));

        response.PageSize.Should().Be(5);
    }

    [Fact]
    public async Task GetLogsAsync_WithMissingDirectory_ReturnsEmptyPage()
    {
        var missing = Path.Combine(_directory, "does-not-exist");
        var service = new FileLogReaderService(
            missing,
            NullLogger<FileLogReaderService>.Instance);

        var response = await service.GetLogsAsync(new LogQuery());

        response.TotalCount.Should().Be(0);
        response.Items.Should().BeEmpty();
    }

    private FileLogReaderService CreateService(int maxPageSize = 200) =>
        new(
            _directory,
            NullLogger<FileLogReaderService>.Instance,
            "nutriexercise-*.json",
            maxPageSize);

    private void WriteLog(
        string fileName,
        params (string Timestamp, string Level, string Message)[] entries)
    {
        var lines = entries.Select(entry =>
            $"{{\"Timestamp\":\"{entry.Timestamp}\",\"Level\":\"{entry.Level}\",\"RenderedMessage\":\"{entry.Message}\"}}");

        File.WriteAllLines(Path.Combine(_directory, fileName), lines);
    }
}
