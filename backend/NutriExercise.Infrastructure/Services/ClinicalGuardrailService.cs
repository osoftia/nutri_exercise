using NutriExercise.Core.Configuration;
using NutriExercise.Core.DTOs;
using NutriExercise.Core.Interfaces;

namespace NutriExercise.Infrastructure.Services;

public class ClinicalGuardrailService : IClinicalGuardrailService
{
    public GuardrailSummary Evaluate(IEnumerable<string> conditions)
    {
        ArgumentNullException.ThrowIfNull(conditions);

        var activeConditions = conditions
            .Where(condition => !string.IsNullOrWhiteSpace(condition))
            .Select(condition => condition.Trim())
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .ToList();

        var guardrails = new List<ConditionGuardrail>();
        var red = new List<string>();
        var green = new List<string>();

        foreach (var condition in activeConditions)
        {
            var rule = ClinicalConditionCatalog.Rules.TryGetValue(condition, out var match)
                ? match
                : ClinicalConditionCatalog.Generic(condition);

            guardrails.Add(rule);
            red.AddRange(rule.RestrictedIngredients);
            green.AddRange(rule.BeneficialIngredients);
        }

        return new GuardrailSummary(
            Distinct(red),
            Distinct(green),
            guardrails);
    }

    private static IReadOnlyList<string> Distinct(IEnumerable<string> values) =>
        values.Distinct(StringComparer.OrdinalIgnoreCase).ToList();
}
