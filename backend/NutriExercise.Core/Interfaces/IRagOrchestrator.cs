using NutriExercise.Core.DTOs;

namespace NutriExercise.Core.Interfaces;

public interface IRagOrchestrator
{
    Task<RagResponse> ExecuteQueryAsync(
        RagRequest request,
        CancellationToken cancellationToken = default);

    Task<RagIngestResponse> IngestAsync(
        RagIngestRequest request,
        int userId,
        CancellationToken cancellationToken = default);
}
