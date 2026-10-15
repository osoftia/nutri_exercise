using NutriExercise.Core.DTOs;

namespace NutriExercise.Core.Interfaces;

public interface IVectorSearchService
{
    Task<IReadOnlyList<string>> SearchAsync(
        string query,
        double similarityThreshold,
        CancellationToken cancellationToken = default);

    Task<VectorSearchResult> SearchWithScoresAsync(
        string query,
        double similarityThreshold,
        CancellationToken cancellationToken = default);
}
