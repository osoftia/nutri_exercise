namespace NutriExercise.Core.Entities;

public class DailyLogRecord
{
    public Guid Id { get; set; } = Guid.NewGuid();

    public Guid? UserId { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public string OriginalText { get; set; } = string.Empty;

    public int Calories { get; set; }

    public int Protein { get; set; }

    public int Carbs { get; set; }

    public int Fats { get; set; }

    public string MuscleGroups { get; set; } = string.Empty;

    public Guid? TraceId { get; set; }
}