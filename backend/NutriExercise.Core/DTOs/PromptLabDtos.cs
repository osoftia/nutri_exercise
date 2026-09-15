namespace NutriExercise.Core.DTOs;

public record PromptLabRunRequest(
    string SystemPrompt,
    double Temperature,
    double SimilarityThreshold,
    string TestQuery);

public record PromptLabRunResponse(
    string GeneratedResponse,
    int RetrievedContextCount);
