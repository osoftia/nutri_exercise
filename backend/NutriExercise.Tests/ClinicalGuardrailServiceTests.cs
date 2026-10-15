using FluentAssertions;
using NutriExercise.Infrastructure.Services;

namespace NutriExercise.Tests;

public class ClinicalGuardrailServiceTests
{
    private readonly ClinicalGuardrailService _service = new();

    [Fact]
    public void Evaluate_WithKnownCondition_ReturnsRedAndGreenContainers()
    {
        var summary = _service.Evaluate(new[] { "High Cholesterol" });

        summary.RedContainers.Should().Contain("Red meat");
        summary.RedContainers.Should().Contain("Trans fats");
        summary.GreenContainers.Should().Contain("Oats");
        summary.GreenContainers.Should().Contain("Olive oil");
        summary.Conditions.Should().ContainSingle(c => c.Condition == "High Cholesterol");
    }

    [Fact]
    public void Evaluate_WithUnknownCondition_ReturnsGenericRule()
    {
        var summary = _service.Evaluate(new[] { "Mystery Syndrome" });

        summary.Conditions.Should().ContainSingle(c => c.Condition == "Mystery Syndrome");
        summary.RedContainers.Should().Contain("Ultra-processed foods");
        summary.GreenContainers.Should().Contain("Whole foods");
    }

    [Fact]
    public void Evaluate_WithMultipleConditions_AggregatesAndDeduplicates()
    {
        var summary = _service.Evaluate(new[] { "Diabetes", "Gout", "Diabetes" });

        summary.Conditions.Should().HaveCount(2);
        summary.RedContainers.Should().Contain("Refined sugar");
        summary.RedContainers.Should().Contain("Beer");
        summary.RedContainers.Should().OnlyHaveUniqueItems();
        summary.GreenContainers.Should().OnlyHaveUniqueItems();
    }

    [Fact]
    public void Evaluate_IsCaseInsensitive()
    {
        var summary = _service.Evaluate(new[] { "diabetes" });

        summary.Conditions.Should().ContainSingle(c => c.Condition == "Diabetes");
        summary.RedContainers.Should().Contain("Refined sugar");
    }

    [Fact]
    public void Evaluate_WithEmptyConditions_ReturnsEmptySummary()
    {
        var summary = _service.Evaluate(Array.Empty<string>());

        summary.Conditions.Should().BeEmpty();
        summary.RedContainers.Should().BeEmpty();
        summary.GreenContainers.Should().BeEmpty();
    }
}
