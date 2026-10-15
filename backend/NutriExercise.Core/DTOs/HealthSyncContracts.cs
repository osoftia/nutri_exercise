namespace NutriExercise.Core.DTOs;

public record HealthMetricDto(
    string MetricType,
    double Value,
    string Unit,
    DateTimeOffset Timestamp);

public record HealthMetricsSyncRequest(
    IReadOnlyList<HealthMetricDto>? Metrics,
    int? UserId = null);

public record HealthMetricSyncResult(
    string MetricType,
    DateTimeOffset Timestamp,
    bool Created);

public record HealthSyncResponse(
    int Received,
    int Inserted,
    int Updated,
    IReadOnlyList<HealthMetricSyncResult> Results);
