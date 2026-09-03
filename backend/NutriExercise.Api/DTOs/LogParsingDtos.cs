namespace NutriExercise.Api.DTOs;

public class ParseLogRequest
{
    public string Text { get; set; } = string.Empty;
}

public class ParsedLogResponse
{
    public int Calories { get; set; }

    public double? Protein { get; set; }

    public double? Carbs { get; set; }

    public double? Fat { get; set; }

    public List<string> Muscles { get; set; } = new();
}
