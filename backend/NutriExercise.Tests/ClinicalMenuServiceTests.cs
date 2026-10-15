using FluentAssertions;
using Microsoft.EntityFrameworkCore;
using Moq;
using NutriExercise.Core.DTOs;
using NutriExercise.Core.Interfaces;
using NutriExercise.Infrastructure.Data;
using NutriExercise.Infrastructure.Services;

namespace NutriExercise.Tests;

public class ClinicalMenuServiceTests
{
    private const string AiJson =
        "{\"summary\":\"Balanced plan\",\"meals\":[" +
        "{\"mealType\":\"Breakfast\",\"name\":\"Oat bowl\",\"description\":\"Fiber rich\"," +
        "\"ingredients\":[\"Oats\",\"Berries\"],\"container\":\"green\"}," +
        "{\"mealType\":\"Lunch\",\"name\":\"Fried platter\",\"description\":\"Avoid\"," +
        "\"ingredients\":[\"Red meat\"],\"container\":\"red\"}]," +
        "\"exercises\":[{\"name\":\"Walk\",\"duration\":\"30 min\",\"notes\":\"Low impact\"}]}";

    private readonly Mock<IVectorSearchService> _vectorMock = new();
    private readonly Mock<IAiModelService> _aiModelMock = new();
    private readonly Mock<IRagLogger> _ragLoggerMock = new();

    private static AppDbContext CreateContext(string name)
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(name)
            .Options;

        return new AppDbContext(options);
    }

    private ClinicalMenuService CreateService(AppDbContext context) =>
        new(
            _vectorMock.Object,
            _aiModelMock.Object,
            new ClinicalGuardrailService(),
            new ClinicalMenuStore(new ClinicalMenuRepository(context), _ragLoggerMock.Object),
            _ragLoggerMock.Object);

    private void SetupAiResponse(string response)
    {
        _aiModelMock
            .Setup(a => a.GenerateAsync(
                It.IsAny<string>(),
                It.IsAny<string>(),
                It.IsAny<IReadOnlyList<string>>(),
                It.IsAny<double>(),
                It.IsAny<CancellationToken>()))
            .ReturnsAsync(response);
    }

    private void SetupContexts()
    {
        _vectorMock
            .Setup(v => v.SearchAsync(
                It.IsAny<string>(),
                It.IsAny<double>(),
                It.IsAny<CancellationToken>()))
            .ReturnsAsync(new List<string> { "Limit saturated fats." });
    }

    [Fact]
    public async Task GenerateAsync_WithValidJson_PersistsLogAndPlanAndMapsContainers()
    {
        await using var context = CreateContext(nameof(GenerateAsync_WithValidJson_PersistsLogAndPlanAndMapsContainers));
        SetupContexts();
        SetupAiResponse(AiJson);

        var response = await CreateService(context).GenerateAsync(
            new ClinicalMenuRequest("High Cholesterol", "Fatigue"),
            1);

        response.Menu.Meals.Should().HaveCount(2);
        response.Menu.Meals.Should().Contain(m => m.Container == "red");
        response.Menu.Meals.Should().Contain(m => m.Container == "green");
        response.Menu.Exercises.Should().ContainSingle(e => e.Name == "Walk");
        response.Guardrails.RedContainers.Should().Contain("Red meat");
        context.DailySymptomLogs.Should().ContainSingle();
        context.ClinicalMenuPlans.Should().ContainSingle();
    }

    [Fact]
    public async Task GenerateAsync_WithMalformedJson_FallsBackToRawSummary()
    {
        await using var context = CreateContext(nameof(GenerateAsync_WithMalformedJson_FallsBackToRawSummary));
        SetupContexts();
        SetupAiResponse("not a json menu");

        var response = await CreateService(context).GenerateAsync(
            new ClinicalMenuRequest("Gout"),
            1);

        response.Menu.Summary.Should().Be("not a json menu");
        response.Menu.Meals.Should().BeEmpty();
        context.ClinicalMenuPlans.Should().ContainSingle();
    }

    [Fact]
    public async Task GenerateAsync_WithEmptyAiResponse_Throws()
    {
        await using var context = CreateContext(nameof(GenerateAsync_WithEmptyAiResponse_Throws));
        SetupContexts();
        SetupAiResponse(string.Empty);

        var act = async () => await CreateService(context).GenerateAsync(
            new ClinicalMenuRequest("Diabetes"),
            1);

        await act.Should().ThrowAsync<InvalidOperationException>();
        context.ClinicalMenuPlans.Should().BeEmpty();
    }

    [Fact]
    public async Task GenerateAsync_WithMultipleConditions_RecordsAllInSymptomLog()
    {
        await using var context = CreateContext(nameof(GenerateAsync_WithMultipleConditions_RecordsAllInSymptomLog));
        SetupContexts();
        SetupAiResponse(AiJson);

        var response = await CreateService(context).GenerateAsync(
            new ClinicalMenuRequest("Diabetes, Gout", null),
            1);

        response.ActiveConditions.Should().HaveCount(2);
        context.DailySymptomLogs.Should().ContainSingle(log =>
            log.ActiveConditions.Contains("Diabetes") && log.ActiveConditions.Contains("Gout"));
    }
}
