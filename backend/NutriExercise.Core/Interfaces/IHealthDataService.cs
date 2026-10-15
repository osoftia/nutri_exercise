using NutriExercise.Core.DTOs;

namespace NutriExercise.Core.Interfaces;

public interface IHealthDataService
{
    Task<HealthSyncResponse> SyncAsync(
        HealthMetricsSyncRequest request,
        CancellationToken cancellationToken = default);
}
