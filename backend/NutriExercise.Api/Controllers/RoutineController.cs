using Microsoft.AspNetCore.Mvc;
using NutriExercise.Core.Entities;
using NutriExercise.Core.Interfaces;

namespace NutriExercise.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class RoutineController : ControllerBase
{
    private readonly IAiService _aiService;
    private readonly IRoutineRepository _routineRepository;

    public RoutineController(IAiService aiService, IRoutineRepository routineRepository)
    {
        _aiService = aiService;
        _routineRepository = routineRepository;
    }

    [HttpPost("generate")]
    public async Task<IActionResult> Generate([FromBody] GenerateRoutineRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.UserPreferences))
        {
            return BadRequest("User preferences are required.");
        }

        var generatedText = await _aiService.GenerateRoutineAsync(request.UserPreferences);

        var routine = new Routine
        {
            Name = "AI Generated Routine",
            DayOfWeek = "Weekly",
            Description = generatedText
        };

        await _routineRepository.AddAsync(routine);

        return Ok(routine);
    }

    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var routines = await _routineRepository.GetAllAsync();
        return Ok(routines);
    }

    [HttpGet("{id:int}")]
    public async Task<IActionResult> GetById(int id)
    {
        var routine = await _routineRepository.GetByIdAsync(id);
        if (routine is null)
        {
            return NotFound();
        }

        return Ok(routine);
    }

    [HttpDelete("{id:int}")]
    public async Task<IActionResult> Delete(int id)
    {
        var routine = await _routineRepository.GetByIdAsync(id);
        if (routine is null)
        {
            return NotFound();
        }

        await _routineRepository.DeleteAsync(id);
        return NoContent();
    }
}

public class GenerateRoutineRequest
{
    public string UserPreferences { get; set; } = string.Empty;
}
