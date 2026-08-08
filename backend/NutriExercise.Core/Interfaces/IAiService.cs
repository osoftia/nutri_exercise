namespace NutriExercise.Core.Interfaces;

public interface IAiService
{
    Task<string> GenerateRoutineAsync(string userPreferences, CancellationToken cancellationToken = default);
}
