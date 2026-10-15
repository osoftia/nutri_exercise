using NutriExercise.Core.DTOs;

namespace NutriExercise.Core.Configuration;

public static class ClinicalConditionCatalog
{
    public static IReadOnlyDictionary<string, ConditionGuardrail> Rules { get; } =
        new Dictionary<string, ConditionGuardrail>(StringComparer.OrdinalIgnoreCase)
        {
            ["High Cholesterol"] = new(
                "High Cholesterol",
                new[] { "Red meat", "Butter", "Lard", "Fried foods", "Trans fats", "Full-fat dairy", "Processed pastries" },
                new[] { "Oats", "Olive oil", "Nuts", "Fatty fish", "Legumes", "Fruits", "Vegetables" },
                "Prioritize soluble fiber and unsaturated fats; limit saturated and trans fats."),
            ["Diabetes"] = new(
                "Diabetes",
                new[] { "Refined sugar", "White bread", "Soda", "Candy", "Pastries", "Sweetened juices" },
                new[] { "Whole grains", "Leafy greens", "Legumes", "Nuts", "Lean protein", "Non-starchy vegetables" },
                "Favor low-glycemic carbohydrates and consistent protein; avoid added sugars."),
            ["Gout"] = new(
                "Gout",
                new[] { "Red meat", "Organ meats", "Shellfish", "Beer", "Sugary drinks", "High-fructose corn syrup" },
                new[] { "Water", "Cherries", "Low-fat dairy", "Vegetables", "Whole grains", "Vitamin C foods" },
                "Reduce purine-rich foods and alcohol; stay well hydrated."),
            ["Hypertension"] = new(
                "Hypertension",
                new[] { "Salt", "Processed meats", "Canned soups", "Pickles", "Fast food", "Salty snacks" },
                new[] { "Potassium-rich foods", "Bananas", "Leafy greens", "Beets", "Oats", "Garlic" },
                "Adopt a low-sodium, potassium-rich dietary pattern."),
            ["Celiac Disease"] = new(
                "Celiac Disease",
                new[] { "Wheat", "Barley", "Rye", "Malt", "Regular pasta", "Regular bread" },
                new[] { "Rice", "Quinoa", "Corn", "Gluten-free oats", "Fruits", "Vegetables" },
                "Exclude all gluten-containing grains and cross-contamination sources."),
            ["Lactose Intolerance"] = new(
                "Lactose Intolerance",
                new[] { "Milk", "Cheese", "Ice cream", "Butter", "Cream", "Whey" },
                new[] { "Lactose-free dairy", "Almond milk", "Soy milk", "Leafy greens", "Calcium-rich alternatives" },
                "Use lactose-free or plant-based dairy and monitor calcium intake.")
        };

    public static ConditionGuardrail Generic(string condition) =>
        new(
            condition,
            new[] { "Ultra-processed foods", "Excess added sugar", "Trans fats" },
            new[] { "Whole foods", "Vegetables", "Lean protein", "Water" },
            "No specific rule found. Follow a balanced, minimally processed diet and medical advice.");
}
