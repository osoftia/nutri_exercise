using System.Text.Json;
using NutriExercise.Core.DTOs;
using NutriExercise.Core.Interfaces;

namespace NutriExercise.Infrastructure.Services;

internal static class ClinicalMenuParser
{
    private static readonly JsonSerializerOptions SerializerOptions = new()
    {
        PropertyNameCaseInsensitive = true
    };

    public static ClinicalMenuContent Parse(string generatedText, IRagLogger ragLogger)
    {
        ArgumentNullException.ThrowIfNull(ragLogger);

        try
        {
            var payload = JsonSerializer.Deserialize<ClinicalAiMenu>(
                ExtractJson(generatedText),
                SerializerOptions);

            if (payload is not null && payload.Meals.Count > 0)
            {
                return new ClinicalMenuContent(
                    string.IsNullOrWhiteSpace(payload.Summary) ? "Clinical menu" : payload.Summary,
                    payload.Meals.Select(MapMeal).ToList(),
                    payload.Exercises.Select(MapExercise).ToList());
            }
        }
        catch (JsonException ex)
        {
            ragLogger.LogError(
                ex,
                "Clinical menu JSON parsing failed. Falling back to raw text.");
        }

        return new ClinicalMenuContent(
            generatedText,
            Array.Empty<ClinicalMealItem>(),
            Array.Empty<ClinicalExerciseItem>());
    }

    private static ClinicalMealItem MapMeal(ClinicalAiMeal meal) =>
        new(
            meal.MealType,
            meal.Name,
            meal.Description,
            meal.Ingredients,
            string.Equals(meal.Container, "red", StringComparison.OrdinalIgnoreCase)
                ? "red"
                : "green");

    private static ClinicalExerciseItem MapExercise(ClinicalAiExercise exercise) =>
        new(exercise.Name, exercise.Duration, exercise.Notes);

    private static string ExtractJson(string text)
    {
        var trimmed = text.Trim();

        if (!trimmed.StartsWith("```", StringComparison.Ordinal))
        {
            return trimmed;
        }

        var firstBrace = trimmed.IndexOf('{', StringComparison.Ordinal);
        var lastBrace = trimmed.LastIndexOf('}');

        return firstBrace >= 0 && lastBrace > firstBrace
            ? trimmed[firstBrace..(lastBrace + 1)]
            : trimmed;
    }

    private sealed class ClinicalAiMenu
    {
        public string Summary { get; set; } = string.Empty;

        public List<ClinicalAiMeal> Meals { get; set; } = new();

        public List<ClinicalAiExercise> Exercises { get; set; } = new();
    }

    private sealed class ClinicalAiMeal
    {
        public string MealType { get; set; } = string.Empty;

        public string Name { get; set; } = string.Empty;

        public string Description { get; set; } = string.Empty;

        public List<string> Ingredients { get; set; } = new();

        public string Container { get; set; } = "green";
    }

    private sealed class ClinicalAiExercise
    {
        public string Name { get; set; } = string.Empty;

        public string Duration { get; set; } = string.Empty;

        public string Notes { get; set; } = string.Empty;
    }
}
