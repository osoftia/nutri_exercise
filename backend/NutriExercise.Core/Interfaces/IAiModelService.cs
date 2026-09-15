namespace NutriExercise.Core.Interfaces;

public interface IAiModelService
{
    Task<string> GenerateAsync(
        string systemPrompt,
        string userQuery,
        IReadOnlyList<string> contexts,
        double temperature,
        CancellationToken cancellationToken = default);
}
