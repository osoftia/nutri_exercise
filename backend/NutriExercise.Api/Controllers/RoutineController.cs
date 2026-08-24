using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using NutriExercise.Core.Entities;
using NutriExercise.Core.Interfaces;
using NutriExercise.Infrastructure.Data;

namespace NutriExercise.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class RoutineController : ControllerBase
{
    private readonly IAiService _aiService;
    private readonly IRoutineRepository _routineRepository;
    private readonly IResearchDocumentRepository _documentRepository;
    private readonly AppDbContext _dbContext;

    public RoutineController(IAiService aiService, IRoutineRepository routineRepository, IResearchDocumentRepository documentRepository, AppDbContext dbContext)
    {
        _aiService = aiService;
        _routineRepository = routineRepository;
        _documentRepository = documentRepository;
        _dbContext = dbContext;
    }

    [HttpPost("generate")]
    public async Task<IActionResult> Generate([FromBody] GenerateRoutineRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.UserPreferences))
        {
            return BadRequest("User preferences are required.");
        }

        var queryVector = await _aiService.GenerateEmbeddingAsync(request.UserPreferences);
        var relevantDocs = await _documentRepository.SearchSimilarDocumentsAsync(queryVector);

        var contextText = string.Join("\n", relevantDocs.Select(d => d.Content));
        var augmentedPrompt =
            $"Utilizando EXCLUSIVAMENTE este conocimiento científico:\n{contextText}\n\n" +
            $"Genera una rutina basada en esta petición del usuario: {request.UserPreferences}";

        var generatedText = await _aiService.GenerateRoutineAsync(augmentedPrompt);

        var routine = new Routine
        {
            Name = "AI Generated Routine",
            DayOfWeek = "Weekly",
            Description = generatedText
        };

        await _routineRepository.AddAsync(routine);

        var interaction = new AiInteraction
        {
            Id = Guid.NewGuid(),
            UserPrompt = request.UserPreferences,
            GeneratedRoutine = generatedText,
            ModelUsed = "llama3-RAG",
            UsedContext = contextText,
            CreatedAt = DateTime.UtcNow
        };

        _dbContext.AiInteractions.Add(interaction);
        await _dbContext.SaveChangesAsync();

        return Ok(new
        {
            Routine = routine,
            InteractionId = interaction.Id
        });
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
