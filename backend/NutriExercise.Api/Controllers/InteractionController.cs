using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using NutriExercise.Core.Entities;
using NutriExercise.Infrastructure.Data;

namespace NutriExercise.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class InteractionController : ControllerBase
{
    private readonly AppDbContext _dbContext;

    public InteractionController(AppDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    [HttpGet("history")]
    public async Task<IActionResult> GetHistory()
    {
        var interactions = await _dbContext.AiInteractions
            .OrderByDescending(i => i.CreatedAt)
            .ToListAsync();

        return Ok(interactions);
    }

    [HttpPut("{id:guid}/feedback")]
    public async Task<IActionResult> SubmitFeedback(Guid id, [FromBody] FeedbackRequest request)
    {
        var interaction = await _dbContext.AiInteractions.FindAsync(id);
        if (interaction is null)
        {
            return NotFound();
        }

        interaction.IsCorrect = request.IsCorrect;
        await _dbContext.SaveChangesAsync();

        return Ok();
    }
}

public class FeedbackRequest
{
    public bool IsCorrect { get; set; }
}
