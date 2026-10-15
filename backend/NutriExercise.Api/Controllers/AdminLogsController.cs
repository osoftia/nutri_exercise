using Microsoft.AspNetCore.Mvc;
using NutriExercise.Core.DTOs;
using NutriExercise.Core.Interfaces;

namespace NutriExercise.Api.Controllers;

[ApiController]
[Route("api/admin/logs")]
public class AdminLogsController : ControllerBase
{
    private readonly ILogReaderService _logReaderService;

    public AdminLogsController(ILogReaderService logReaderService)
    {
        ArgumentNullException.ThrowIfNull(logReaderService);

        _logReaderService = logReaderService;
    }

    [HttpGet]
    public async Task<IActionResult> GetLogs(
        [FromQuery] DateTimeOffset? startDate = null,
        [FromQuery] DateTimeOffset? endDate = null,
        [FromQuery] string? logLevel = null,
        [FromQuery] string? tag = null,
        [FromQuery] int pageNumber = 1,
        [FromQuery] int pageSize = 50,
        CancellationToken cancellationToken = default)
    {
        var query = new LogQuery(
            startDate,
            endDate,
            logLevel,
            tag,
            pageNumber,
            pageSize);

        var response = await _logReaderService.GetLogsAsync(query, cancellationToken);

        return Ok(response);
    }
}
