using Microsoft.AspNetCore.Mvc;
using NutriExercise.Core.DTOs;
using NutriExercise.Core.Interfaces;

namespace NutriExercise.Api.Controllers;

[ApiController]
[Route("api/health-sync")]
public class HealthSyncController : ControllerBase
{
    private readonly IHealthDataService _healthDataService;

    public HealthSyncController(IHealthDataService healthDataService)
    {
        ArgumentNullException.ThrowIfNull(healthDataService);

        _healthDataService = healthDataService;
    }

    [HttpPost("metrics")]
    public async Task<IActionResult> SyncMetrics(
        [FromBody] HealthMetricsSyncRequest request,
        CancellationToken cancellationToken = default)
    {
        if (request?.Metrics is null || request.Metrics.Count == 0)
        {
            return BadRequest("At least one health metric is required.");
        }

        var response = await _healthDataService.SyncAsync(request, cancellationToken);

        return Ok(response);
    }
}
