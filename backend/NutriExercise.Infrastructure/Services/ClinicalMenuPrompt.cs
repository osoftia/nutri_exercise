using NutriExercise.Core.DTOs;

namespace NutriExercise.Infrastructure.Services;

internal static class ClinicalMenuPrompt
{
    public const string SystemPrompt =
        "You are a clinical dietitian and exercise coach. Using the provided clinical guidelines, " +
        "produce an offline-ready daily menu and exercise plan for the patient. " +
        "Tag every meal with a container: 'red' for restricted/harmful foods and 'green' for beneficial foods. " +
        "Respond ONLY with a valid JSON object and no extra text: " +
        "{\"summary\":\"...\",\"meals\":[{\"mealType\":\"Breakfast\",\"name\":\"...\"," +
        "\"description\":\"...\",\"ingredients\":[\"...\"],\"container\":\"green\"}]," +
        "\"exercises\":[{\"name\":\"...\",\"duration\":\"30 min\",\"notes\":\"...\"}]}";

    public static IReadOnlyList<string> SplitConditions(string condition) =>
        condition
            .Split(new[] { ',', ';', '|' }, StringSplitOptions.RemoveEmptyEntries)
            .Select(value => value.Trim())
            .Where(value => value.Length > 0)
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .ToList();

    public static string BuildRetrievalQuery(
        ClinicalMenuRequest request,
        IReadOnlyList<string> conditions) =>
        $"Clinical dietary guidelines for {string.Join(", ", conditions)}. " +
        $"Symptoms: {request.Symptoms ?? "None"}";

    public static string BuildUserQuery(
        ClinicalMenuRequest request,
        GuardrailSummary guardrails) =>
        $"Active conditions: {string.Join(", ", guardrails.Conditions.Select(c => c.Condition))}\n" +
        $"Daily symptoms: {request.Symptoms ?? "None reported"}\n" +
        $"Restricted ingredients (red containers): {string.Join(", ", guardrails.RedContainers)}\n" +
        $"Beneficial ingredients (green containers): {string.Join(", ", guardrails.GreenContainers)}";
}
