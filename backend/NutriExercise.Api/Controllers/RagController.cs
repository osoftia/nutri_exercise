using Microsoft.AspNetCore.Mvc;
using NutriExercise.Core.Configuration;
using NutriExercise.Core.DTOs;
using NutriExercise.Core.Interfaces;

namespace NutriExercise.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class RagController : ControllerBase
{
    private readonly IRagOrchestrator _orchestrator;
    private readonly IUserRepository _userRepository;
    private readonly IRagLogger _ragLogger;

    public RagController(
        IRagOrchestrator orchestrator,
        IUserRepository userRepository,
        IRagLogger ragLogger)
    {
        ArgumentNullException.ThrowIfNull(orchestrator);
        ArgumentNullException.ThrowIfNull(userRepository);
        ArgumentNullException.ThrowIfNull(ragLogger);

        _orchestrator = orchestrator;
        _userRepository = userRepository;
        _ragLogger = ragLogger;
    }

    [HttpPost("query")]
    public async Task<IActionResult> Query(
        [FromBody] RagRequest request,
        CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(request);

        var userId = await ResolveUserIdAsync(request.UserId, cancellationToken);

        var response = await _orchestrator.ExecuteQueryAsync(request, cancellationToken);

        _ragLogger.LogInfo(
            "Query executed. UserId={UserId}, LatencyMs={LatencyMs}, Contexts={ContextCount}.",
            userId,
            response.Telemetry.LatencyMs,
            response.RetrievedContexts.Count);

        return Ok(response);
    }

    [HttpPost("ingest")]
    public async Task<IActionResult> Ingest(
        [FromBody] RagIngestRequest request,
        CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(request);

        if (string.IsNullOrWhiteSpace(request.Title) ||
            string.IsNullOrWhiteSpace(request.Content) ||
            string.IsNullOrWhiteSpace(request.BodyZone))
        {
            return BadRequest("Title, Content, and BodyZone are required.");
        }

        var userId = await ResolveUserIdAsync(request.UserId, cancellationToken);

        var response = await _orchestrator.IngestAsync(
            request,
            userId,
            cancellationToken);

        _ragLogger.LogInfo(
            "Ingest endpoint completed. DocumentId={DocumentId}, UserId={UserId}, BodyZone={BodyZone}.",
            response.Id,
            userId,
            response.BodyZone);

        return Ok(response);
    }

    private async Task<int> ResolveUserIdAsync(
        int? requestedUserId,
        CancellationToken cancellationToken)
    {
        if (requestedUserId.HasValue && requestedUserId.Value > 0)
        {
            var user = await _userRepository.GetByIdAsync(
                requestedUserId.Value,
                cancellationToken);

            if (user is not null)
            {
                return user.Id;
            }
        }

        var defaultUser = await _userRepository.EnsureSeedUserAsync(cancellationToken);

        return defaultUser.Id;
    }
}
