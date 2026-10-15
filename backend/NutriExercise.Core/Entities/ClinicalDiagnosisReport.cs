namespace NutriExercise.Core.Entities;

public class ClinicalDiagnosisReport
{
    public Guid Id { get; set; }

    public int UserId { get; set; }

    public string Preferences { get; set; } = string.Empty;

    public string Conditions { get; set; } = string.Empty;

    public string DiagnosticReport { get; set; } = string.Empty;

    public string MealSuggestions { get; set; } = string.Empty;

    public string ModelUsed { get; set; } = string.Empty;

    public DateTime CreatedAt { get; set; }
}
