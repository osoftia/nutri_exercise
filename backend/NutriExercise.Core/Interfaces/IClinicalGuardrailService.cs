using NutriExercise.Core.DTOs;

namespace NutriExercise.Core.Interfaces;

public interface IClinicalGuardrailService
{
    GuardrailSummary Evaluate(IEnumerable<string> conditions);
}
