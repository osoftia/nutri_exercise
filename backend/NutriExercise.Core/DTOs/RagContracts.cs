namespace NutriExercise.Core.DTOs;

public record RagRequest(
    string SystemPrompt,
    double Temperature,
    double SimilarityThreshold,
    string Query,
    int? UserId = null);

public record RagResponse(
    string GeneratedText,
    List<string> RetrievedContexts,
    TelemetryData Telemetry);

public record RagIngestRequest(
    string Title,
    string Content,
    string BodyZone,
    int? UserId = null);

public record RagIngestResponse(
    Guid Id,
    string Title,
    string BodyZone,
    int UserId,
    int Dimensions,
    string Message);

public record TelemetryData(
    long LatencyMs,
    List<double> PgVectorScores);
