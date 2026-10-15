namespace NutriExercise.Core.DTOs;

public record ClinicalMenuRequest(
    string Condition,
    string? Symptoms = null,
    int? UserId = null);

public record ClinicalMenuResponse(
    Guid PlanId,
    int UserId,
    string Condition,
    IReadOnlyList<string> ActiveConditions,
    GuardrailSummary Guardrails,
    ClinicalMenuContent Menu,
    string ModelUsed,
    DateTime CreatedAt);

public record GuardrailSummary(
    IReadOnlyList<string> RedContainers,
    IReadOnlyList<string> GreenContainers,
    IReadOnlyList<ConditionGuardrail> Conditions);

public record ConditionGuardrail(
    string Condition,
    IReadOnlyList<string> RestrictedIngredients,
    IReadOnlyList<string> BeneficialIngredients,
    string Guidance);

public record ClinicalMenuContent(
    string Summary,
    IReadOnlyList<ClinicalMealItem> Meals,
    IReadOnlyList<ClinicalExerciseItem> Exercises);

public record ClinicalMealItem(
    string MealType,
    string Name,
    string Description,
    IReadOnlyList<string> Ingredients,
    string Container);

public record ClinicalExerciseItem(
    string Name,
    string Duration,
    string Notes);
