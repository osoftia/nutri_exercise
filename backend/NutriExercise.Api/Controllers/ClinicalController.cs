using Microsoft.AspNetCore.Mvc;
using NutriExercise.Core.DTOs;
using NutriExercise.Core.Interfaces;

namespace NutriExercise.Api.Controllers;

[ApiController]
[Route("api/clinical")]
public class ClinicalController : ControllerBase
{
    private readonly IClinicalDiagnosisService _clinicalDiagnosisService;
    private readonly IUserRepository _userRepository;
    private readonly IRagLogger _ragLogger;

    public ClinicalController(
        IClinicalDiagnosisService clinicalDiagnosisService,
        IUserRepository userRepository,
        IRagLogger ragLogger)
    {
        ArgumentNullException.ThrowIfNull(clinicalDiagnosisService);
        ArgumentNullException.ThrowIfNull(userRepository);
        ArgumentNullException.ThrowIfNull(ragLogger);

        _clinicalDiagnosisService = clinicalDiagnosisService;
        _userRepository = userRepository;
        _ragLogger = ragLogger;
    }

    [HttpPost("diagnosis")]
    public async Task<IActionResult> Diagnose(
        [FromBody] ClinicalDiagnosisRequest request,
        CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(request);

        if (string.IsNullOrWhiteSpace(request.Preferences))
        {
            return BadRequest("Preferences are required.");
        }

        var userId = await ResolveUserIdAsync(request.UserId, cancellationToken);

        _ragLogger.LogInfo(
            "Clinical diagnosis request payload. UserId={UserId}, Preferences={Preferences}, Conditions={Conditions}.",
            userId,
            request.Preferences,
            request.Conditions ?? "None reported");

        try
        {
            var response = await _clinicalDiagnosisService.DiagnoseAsync(
                request,
                userId,
                cancellationToken);

            return Ok(response);
        }
        catch (Exception ex)
        {
            _ragLogger.LogError(
                ex,
                "Clinical diagnosis endpoint failed. UserId={UserId}.",
                userId);

            throw;
        }
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
