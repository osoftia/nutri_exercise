using Microsoft.Extensions.Logging;
using NutriExercise.Core.DTOs;
using NutriExercise.Core.Interfaces;
using NutriExercise.Infrastructure.Logging;

namespace NutriExercise.Infrastructure.Services;

#pragma warning disable CA1848 // Runtime-formatted diagnostic messages.
public class FileLogReaderService : ILogReaderService
{
    private readonly string _logDirectory;
    private readonly string _searchPattern;
    private readonly int _maxPageSize;
    private readonly ILogger<FileLogReaderService> _logger;

    public FileLogReaderService(
        string logDirectory,
        ILogger<FileLogReaderService> logger,
        string searchPattern = "nutriexercise-*.json",
        int maxPageSize = 200)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(logDirectory);
        ArgumentNullException.ThrowIfNull(logger);

        _logDirectory = logDirectory;
        _logger = logger;
        _searchPattern = searchPattern;
        _maxPageSize = maxPageSize;
    }

    public Task<PagedLogResponse> GetLogsAsync(
        LogQuery query,
        CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(query);

        var pageNumber = Math.Max(1, query.PageNumber);
        var pageSize = Math.Max(1, Math.Min(query.PageSize, _maxPageSize));

        return Task.Run(
            () => ReadPage(query, pageNumber, pageSize, cancellationToken),
            cancellationToken);
    }

    private PagedLogResponse ReadPage(
        LogQuery query,
        int pageNumber,
        int pageSize,
        CancellationToken cancellationToken)
    {
        var skip = (pageNumber - 1) * pageSize;
        var items = new List<LogEntryDto>(pageSize);
        var total = 0;

        foreach (var file in EnumerateFiles())
        {
            foreach (var line in ReverseFileReader.ReadLines(file, cancellationToken))
            {
                var entry = SerilogJsonLogParser.Parse(line, Path.GetFileName(file));

                if (entry is null || !Matches(entry, query))
                {
                    continue;
                }

                if (total >= skip && items.Count < pageSize)
                {
                    items.Add(entry);
                }

                total++;
            }
        }

        return new PagedLogResponse(items, pageNumber, pageSize, total);
    }

    private IEnumerable<string> EnumerateFiles()
    {
        if (!Directory.Exists(_logDirectory))
        {
            _logger.LogWarning("Log directory {LogDirectory} does not exist.", _logDirectory);

            return Array.Empty<string>();
        }

        // Daily rolling names embed the date (nutriexercise-YYYYMMDD.json), so
        // ordering names descending yields newest files first.
        return Directory
            .EnumerateFiles(_logDirectory, _searchPattern)
            .OrderByDescending(file => Path.GetFileName(file), StringComparer.Ordinal);
    }

    private static bool Matches(LogEntryDto entry, LogQuery query)
    {
        if (query.StartDate.HasValue && entry.Timestamp < query.StartDate.Value)
        {
            return false;
        }

        if (query.EndDate.HasValue && entry.Timestamp > query.EndDate.Value)
        {
            return false;
        }

        if (!string.IsNullOrWhiteSpace(query.LogLevel) &&
            !string.Equals(entry.Level, query.LogLevel.Trim(), StringComparison.OrdinalIgnoreCase))
        {
            return false;
        }

        return string.IsNullOrWhiteSpace(query.Tag) ||
               entry.Message.Contains(query.Tag.Trim(), StringComparison.OrdinalIgnoreCase);
    }
}
#pragma warning restore CA1848
