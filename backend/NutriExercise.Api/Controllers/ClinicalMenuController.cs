using Microsoft.AspNetCore.Mvc;
using NutriExercise.Core.DTOs;
using NutriExercise.Core.Interfaces;

namespace NutriExercise.Api.Controllers;

[ApiController]
[Route("api/rag")]
public class ClinicalMenuController : ControllerBase
{
    private readonly IClinicalMenuService _clinicalMenuService;
    private readonly IUserRepository _userRepository;
    private readonly IRagLogger _ragLogger;

    public ClinicalMenuController(
        IClinicalMenuService clinicalMenuService,
        IUserRepository userRepository,
        IRagLogger ragLogger)
    {
        ArgumentNullException.ThrowIfNull(clinicalMenuService);
        ArgumentNullException.ThrowIfNull(userRepository);
        ArgumentNullException.ThrowIfNull(ragLogger);

        _clinicalMenuService = clinicalMenuService;
        _userRepository = userRepository;
        _ragLogger = ragLogger;
    }

    [HttpPost("clinical-menu")]
    public async Task<IActionResult> Generate(
        [FromBody] ClinicalMenuRequest request,
        CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(request);

        if (string.IsNullOrWhiteSpace(request.Condition))
        {
            return BadRequest("Condition is required.");
        }

        var userId = await ResolveUserIdAsync(request.UserId, cancellationToken);

        _ragLogger.LogInfo(
            "Clinical menu request payload. UserId={UserId}, Condition={Condition}, Symptoms={Symptoms}.",
            userId,
            request.Condition,
            request.Symptoms ?? "None reported");

        try
        {
            var response = await _clinicalMenuService.GenerateAsync(
                request,
                userId,
                cancellationToken);

            return Ok(response);
        }
        catch (Exception ex)
        {
            _ragLogger.LogError(
                ex,
                "Clinical menu generation failed. UserId={UserId}.",
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
