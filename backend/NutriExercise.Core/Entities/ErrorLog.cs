namespace NutriExercise.Core.Entities;

public class ErrorLog
{
    public Guid Id { get; set; } = Guid.NewGuid();

    public DateTime Timestamp { get; set; } = DateTime.UtcNow;

    public string Message { get; set; } = string.Empty;

    public string? StackTrace { get; set; }

    public string Module { get; set; } = string.Empty;
}