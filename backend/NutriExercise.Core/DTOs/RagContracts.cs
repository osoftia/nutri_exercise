namespace NutriExercise.Core.DTOs;

public record RagRequest(
    string SystemPrompt,
    double Temperature,
    double SimilarityThreshold,
    string Query);

public record RagResponse(
    string GeneratedText,
    List<string> RetrievedContexts,
    TelemetryData Telemetry);

public record TelemetryData(
    long LatencyMs,
    List<double> PgVectorScores);
