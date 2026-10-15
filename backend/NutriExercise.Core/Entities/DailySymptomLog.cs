namespace NutriExercise.Core.Entities;

public class DailySymptomLog
{
    public Guid Id { get; set; }

    public int UserId { get; set; }

    public string Symptoms { get; set; } = string.Empty;

    public string ActiveConditions { get; set; } = string.Empty;

    public DateTime CreatedAt { get; set; }
}
