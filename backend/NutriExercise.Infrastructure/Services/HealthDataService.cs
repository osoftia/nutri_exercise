using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using NutriExercise.Core.DTOs;
using NutriExercise.Core.Entities;
using NutriExercise.Core.Interfaces;
using NutriExercise.Infrastructure.Data;

namespace NutriExercise.Infrastructure.Services;

#pragma warning disable CA1848 // Runtime-formatted sync diagnostics.
public class HealthDataService : IHealthDataService
{
    private readonly AppDbContext _context;
    private readonly ILogger<HealthDataService> _logger;

    public HealthDataService(AppDbContext context, ILogger<HealthDataService> logger)
    {
        ArgumentNullException.ThrowIfNull(context);
        ArgumentNullException.ThrowIfNull(logger);

        _context = context;
        _logger = logger;
    }

    public async Task<HealthSyncResponse> SyncAsync(
        HealthMetricsSyncRequest request,
        CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(request);

        var metrics = request.Metrics ?? Array.Empty<HealthMetricDto>();
        var now = DateTime.UtcNow;
        var buffer = new Dictionary<(string MetricType, DateTime Timestamp), HealthMetric>();
        var results = new List<HealthMetricSyncResult>(metrics.Count);
        var inserted = 0;
        var updated = 0;

        foreach (var dto in metrics)
        {
            var timestamp = dto.Timestamp.UtcDateTime;
            var metric = await ResolveAsync(request.UserId, dto, timestamp, buffer, cancellationToken);

            if (metric.CreatedNow)
            {
                inserted++;
            }
            else
            {
                Apply(metric.Metric, dto, now);
                updated++;
            }

            results.Add(new HealthMetricSyncResult(dto.MetricType, dto.Timestamp, metric.CreatedNow));
        }

        await _context.SaveChangesAsync(cancellationToken);

        _logger.LogInformation(
            "[HEALTH-INFO] Sync complete. Received={Received}, Inserted={Inserted}, Updated={Updated}.",
            metrics.Count,
            inserted,
            updated);

        return new HealthSyncResponse(metrics.Count, inserted, updated, results);
    }

    private async Task<(HealthMetric Metric, bool CreatedNow)> ResolveAsync(
        int? userId,
        HealthMetricDto dto,
        DateTime timestamp,
        IDictionary<(string MetricType, DateTime Timestamp), HealthMetric> buffer,
        CancellationToken cancellationToken)
    {
        var key = (dto.MetricType, timestamp);

        if (buffer.TryGetValue(key, out var tracked))
        {
            return (tracked, false);
        }

        var existing = await _context.HealthMetrics.FirstOrDefaultAsync(
            metric => metric.UserId == userId &&
                      metric.MetricType == dto.MetricType &&
                      metric.Timestamp == timestamp,
            cancellationToken);

        if (existing is not null)
        {
            buffer[key] = existing;

            return (existing, false);
        }

        var created = Create(userId, dto, timestamp);
        _context.HealthMetrics.Add(created);
        buffer[key] = created;

        return (created, true);
    }

    private static HealthMetric Create(int? userId, HealthMetricDto dto, DateTime timestamp) =>
        new()
        {
            UserId = userId,
            MetricType = dto.MetricType,
            Value = dto.Value,
            Unit = dto.Unit,
            Timestamp = timestamp
        };

    private static void Apply(HealthMetric metric, HealthMetricDto dto, DateTime now)
    {
        metric.Value = dto.Value;
        metric.Unit = dto.Unit;
        metric.UpdatedAt = now;
    }
}
#pragma warning restore CA1848
