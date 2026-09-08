using System.Diagnostics;
using System.Text.Json;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using NutriExercise.Api.DTOs;
using NutriExercise.Core.DTOs;
using NutriExercise.Core.Entities;
using NutriExercise.Core.Interfaces;
using NutriExercise.Infrastructure.Data;

namespace NutriExercise.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class LogController : ControllerBase
{
    private readonly IAiService _aiService;
    private readonly IDailyLogRepository _dailyLogRepository;
    private readonly AppDbContext _dbContext;

    public LogController(IAiService aiService, IDailyLogRepository dailyLogRepository, AppDbContext dbContext)
    {
        _aiService = aiService;
        _dailyLogRepository = dailyLogRepository;
        _dbContext = dbContext;
    }

    [HttpPost("parse")]
    public async Task<IActionResult> Parse([FromBody] ParseLogRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.Text))
        {
            return BadRequest("Log text is required.");
        }

        var stopwatch = Stopwatch.StartNew();
        var json = await _aiService.GenerateJsonAsync(request.Text);
        stopwatch.Stop();

        var response = JsonSerializer.Deserialize<ParsedLogResponse>(
            json,
            new JsonSerializerOptions { PropertyNameCaseInsensitive = true });

        if (response is null)
        {
            return BadRequest("Unable to parse the log into a structured response.");
        }

        var trace = new AiTrainingTrace
        {
            ModelName = "llama3",
            PromptUsed = "Daily log extraction prompt",
            UserRawText = request.Text,
            AiPredictedJson = json,
            ExecutionTimeMs = stopwatch.ElapsedMilliseconds
        };

        _dbContext.AiTrainingTraces.Add(trace);
        await _dbContext.SaveChangesAsync();

        return Ok(new
        {
            TraceId = trace.Id,
            Parsed = response
        });
    }

    [HttpPost("save")]
    public async Task<IActionResult> Save([FromBody] LogSaveRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.OriginalText))
        {
            return BadRequest("Original text is required.");
        }

        var humanJson = JsonSerializer.Serialize(new
        {
            calories = request.Calories,
            protein = request.Protein,
            carbs = request.Carbs,
            fats = request.Fats,
            muscles = request.MuscleGroups
        });

        AiTrainingTrace? trace = null;
        if (request.TraceId.HasValue)
        {
            trace = await _dbContext.AiTrainingTraces.FindAsync(request.TraceId.Value);
        }

        if (trace is not null)
        {
            trace.WasCorrectedByHuman = !string.Equals(trace.AiPredictedJson, humanJson, StringComparison.Ordinal);
            trace.HumanFinalJson = humanJson;
            await _dbContext.SaveChangesAsync();
        }

        var record = new DailyLogRecord
        {
            OriginalText = request.OriginalText,
            Calories = request.Calories,
            Protein = request.Protein,
            Carbs = request.Carbs,
            Fats = request.Fats,
            MuscleGroups = request.MuscleGroups,
            TraceId = request.TraceId
        };

        await _dailyLogRepository.AddAsync(record);

        return Ok(new
        {
            Id = record.Id,
            TraceId = record.TraceId
        });
    }
}