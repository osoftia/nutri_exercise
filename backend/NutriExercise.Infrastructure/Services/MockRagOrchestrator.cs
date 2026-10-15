using NutriExercise.Core.DTOs;
using NutriExercise.Core.Interfaces;

namespace NutriExercise.Infrastructure.Services;

public class MockRagOrchestrator : IRagOrchestrator
{
    private readonly IRagLogger? _ragLogger;

    public MockRagOrchestrator()
    {
    }

    public MockRagOrchestrator(IRagLogger ragLogger)
    {
        _ragLogger = ragLogger;
    }

    public Task<RagResponse> ExecuteQueryAsync(
        RagRequest request,
        CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(request);

        _ragLogger?.LogInfo(
            "Mock query executed (offline mock mode). Query={Query}.",
            request.Query);

        var response = new RagResponse(
            "Mocked RAG response (offline mock mode): progressive overload with 1.6-2.2 g/kg protein.",
            new List<string>
            {
                "Mock context: at least 10 weekly sets per muscle group.",
                "Mock context: 2 to 3 minutes of rest between sets."
            },
            new TelemetryData(
                0,
                new List<double> { 0.92, 0.87 }));

        return Task.FromResult(response);
    }

    public Task<RagIngestResponse> IngestAsync(
        RagIngestRequest request,
        int userId,
        CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(request);

        _ragLogger?.LogInfo(
            "Mock ingestion executed (offline mock mode). UserId={UserId}, Title={Title}, BodyZone={BodyZone}.",
            userId,
            request.Title,
            request.BodyZone);

        var response = new RagIngestResponse(
            Guid.NewGuid(),
            request.Title,
            request.BodyZone,
            userId,
            0,
            "Mock document ingested (offline mock mode).");

        return Task.FromResult(response);
    }
}
