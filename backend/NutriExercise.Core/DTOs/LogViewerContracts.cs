namespace NutriExercise.Core.DTOs;

public record LogEntryDto(
    DateTimeOffset Timestamp,
    string Level,
    string Message,
    string? Exception,
    IReadOnlyDictionary<string, string> Properties,
    string SourceFile);

public record LogQuery(
    DateTimeOffset? StartDate = null,
    DateTimeOffset? EndDate = null,
    string? LogLevel = null,
    string? Tag = null,
    int PageNumber = 1,
    int PageSize = 50);

public record PagedLogResponse(
    IReadOnlyList<LogEntryDto> Items,
    int PageNumber,
    int PageSize,
    int TotalCount);
