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

    /// <summary>
    /// Owner of the interaction. Defaults to the seeded test user
    /// (<c>UserId = 1</c>) when no auth token is provided.
    /// </summary>
    public int UserId { get; set; } = 1;
}
