using System;
namespace NutriExercise.Core.DTOs;

public class LogSaveRequest
{
    public string OriginalText { get; set; } = string.Empty;
    public int Calories { get; set; }
    public int Protein { get; set; }
    public int Carbs { get; set; }
    public int Fats { get; set; }
    public string MuscleGroups { get; set; } = string.Empty;
    public Guid? TraceId { get; set; } 
}