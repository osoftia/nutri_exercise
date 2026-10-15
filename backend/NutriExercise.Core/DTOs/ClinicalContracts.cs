namespace NutriExercise.Core.DTOs;

public record ClinicalDiagnosisRequest(
    string Preferences,
    string? Conditions = null,
    int? UserId = null);

public record ClinicalDiagnosisResponse(
    Guid Id,
    int UserId,
    string DiagnosticReport,
    IReadOnlyList<MealSuggestion> MealSuggestions,
    string ModelUsed,
    DateTime CreatedAt);

public record MealSuggestion(
    string MealType,
    string Name,
    string Description);
