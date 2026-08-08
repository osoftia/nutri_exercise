namespace NutriExercise.Core.Entities;

public class Routine
{
    public int Id { get; set; }

    public string Name { get; set; } = string.Empty;

    public string DayOfWeek { get; set; } = string.Empty;

    public string Description { get; set; } = string.Empty;
}
