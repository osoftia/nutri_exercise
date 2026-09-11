namespace NutriExercise.Core.Entities;

public class AiTrainingTrace
{
    public Guid Id { get; set; } = Guid.NewGuid();

    public DateTime Timestamp { get; set; } = DateTime.UtcNow;

    public string ModelName { get; set; } = string.Empty;

    public string PromptUsed { get; set; } = string.Empty;

    public string UserRawText { get; set; } = string.Empty;

    public string AiPredictedJson { get; set; } = string.Empty;

    public bool WasCorrectedByHuman { get; set; }

    public string? HumanFinalJson { get; set; }

    public long ExecutionTimeMs { get; set; }
}