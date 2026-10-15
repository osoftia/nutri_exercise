namespace NutriExercise.Core.Entities;

public class ClinicalMenuPlan
{
    public Guid Id { get; set; }

    public int UserId { get; set; }

    public string Condition { get; set; } = string.Empty;

    public string MenuJson { get; set; } = string.Empty;

    public string ModelUsed { get; set; } = string.Empty;

    public DateTime CreatedAt { get; set; }
}
