namespace NutriExercise.Core.Entities;

public class HealthMetric
{
    public Guid Id { get; set; } = Guid.NewGuid();

    public int? UserId { get; set; }

    public string MetricType { get; set; } = string.Empty;

    public double Value { get; set; }

    public string Unit { get; set; } = string.Empty;

    public DateTime Timestamp { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
}
