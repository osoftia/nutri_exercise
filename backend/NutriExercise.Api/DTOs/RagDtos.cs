using NutriExercise.Core.Constants;

namespace NutriExercise.Api.DTOs;

/// <summary>
/// DTOs for <c>/api/rag</c>. Property casing mirrors the C# wire
/// contract (PascalCase via System.Text.Json defaults) and matches the
/// Angular <c>RagService</c> expectations.
/// </summary>
public sealed record RagIngestRequest
{
    public string Title { get; init; } = string.Empty;

    public string Content { get; init; } = string.Empty;

    /// <summary>Muscle / body zone tag from the ingestion form.</summary>
    public string BodyZone { get; init; } = string.Empty;

    /// <summary>
    /// Optional explicit owner. Resolved to
    /// <see cref="RagDefaults.DefaultUserId"/> when null/invalid or when
    /// no <c>Authorization</c> token is provided.
    /// </summary>
    public int? UserId { get; init; }

    public int ResolveUserId(bool hasAuthToken) =>
        hasAuthToken ? RagDefaults.ResolveUserId(UserId) : RagDefaults.DefaultUserId;
}

public sealed record RagQueryRequest
{
    public string Query { get; init; } = string.Empty;

    public string SystemPrompt { get; init; } = string.Empty;

    public double Temperature { get; init; } = 0.7;

    public double SimilarityThreshold { get; init; } = 0.8;

    public int? UserId { get; init; }

    public int ResolveUserId(bool hasAuthToken) =>
        hasAuthToken ? RagDefaults.ResolveUserId(UserId) : RagDefaults.DefaultUserId;
}

public sealed record RagMatchDto(string Id, string Title, double Score, string? Content = null);

public sealed record RagTelemetryDto(int LatencyMs, double TokensPerSecond);

public sealed record RagQueryResponse(string Answer, IReadOnlyList<RagMatchDto> MatchedSources, RagTelemetryDto Telemetry);

public sealed record RagIngestResponse(Guid Id, int UserId, string Message);
