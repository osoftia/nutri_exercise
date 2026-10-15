namespace NutriExercise.Core.DTOs;

public record VectorSearchResult(
    IReadOnlyList<string> Contexts,
    IReadOnlyList<double> Scores);
