namespace NutriExercise.Core.Interfaces;

public interface IAiService
{
    Task<string> GenerateRoutineAsync(string userPreferences, CancellationToken cancellationToken = default);

    Task<string> GenerateJsonAsync(string userInput, CancellationToken cancellationToken = default);

    Task<float[]> GenerateEmbeddingAsync(string text, CancellationToken cancellationToken = default);
}
