namespace NutriExercise.Core.Entities;

public class Diet
{
    public int Id { get; set; }

    public string Name { get; set; } = string.Empty;

    public string MealType { get; set; } = string.Empty;

    public string Description { get; set; } = string.Empty;
}
