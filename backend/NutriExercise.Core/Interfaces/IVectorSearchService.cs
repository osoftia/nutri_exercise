namespace NutriExercise.Core.Interfaces;

public interface IVectorSearchService
{
    Task<IReadOnlyList<string>> SearchAsync(
        string query,
        double similarityThreshold,
        CancellationToken cancellationToken = default);
}
