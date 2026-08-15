namespace NutriExercise.Core.Entities;

public class AiInteraction
{
    public Guid Id { get; set; }

    public string UserPrompt { get; set; } = string.Empty;

    public string GeneratedRoutine { get; set; } = string.Empty;

    public string ModelUsed { get; set; } = string.Empty;

    public int? UserRating { get; set; }

    public string? UsedContext { get; set; }

    public bool? IsCorrect { get; set; }

    public DateTime CreatedAt { get; set; }
}
