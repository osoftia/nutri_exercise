using FluentAssertions;
using Microsoft.EntityFrameworkCore;
using Moq;
using NutriExercise.Core.DTOs;
using NutriExercise.Core.Interfaces;
using NutriExercise.Infrastructure.Data;
using NutriExercise.Infrastructure.Services;

namespace NutriExercise.Tests;

public class ClinicalDiagnosisServiceTests
{
    private const string AiJson =
        "{\"diagnosticReport\":\"Low iron risk\",\"mealSuggestions\":" +
        "[{\"mealType\":\"Lunch\",\"name\":\"Spinach bowl\",\"description\":\"Iron rich\"}]}";

    private readonly Mock<IAiModelService> _aiModelMock = new();
    private readonly Mock<IRagLogger> _ragLoggerMock = new();

    private static AppDbContext CreateContext(string name)
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(name)
            .Options;

        return new AppDbContext(options);
    }

    private ClinicalDiagnosisService CreateService(AppDbContext context) =>
        new(_aiModelMock.Object, context, _ragLoggerMock.Object);

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

    [Fact]
    public async Task DiagnoseAsync_WithValidJson_PersistsReportAndMeals()
    {
        await using var context = CreateContext(nameof(DiagnoseAsync_WithValidJson_PersistsReportAndMeals));
        SetupAiResponse(AiJson);

        var response = await CreateService(context).DiagnoseAsync(
            new ClinicalDiagnosisRequest("Vegetarian", "Anemia"),
            1);

        response.DiagnosticReport.Should().Be("Low iron risk");
        response.MealSuggestions.Should().ContainSingle(m => m.Name == "Spinach bowl");
        response.ModelUsed.Should().Be("llama3-clinical");
        context.ClinicalDiagnosisReports.Should().ContainSingle();
    }

    [Fact]
    public async Task DiagnoseAsync_WithMalformedJson_PersistsRawText()
    {
        await using var context = CreateContext(nameof(DiagnoseAsync_WithMalformedJson_PersistsRawText));
        SetupAiResponse("plain text diagnosis without json");

        var response = await CreateService(context).DiagnoseAsync(
            new ClinicalDiagnosisRequest("Keto"),
            1);

        response.DiagnosticReport.Should().Be("plain text diagnosis without json");
        response.MealSuggestions.Should().BeEmpty();
        context.ClinicalDiagnosisReports.Should().ContainSingle();
    }

    [Fact]
    public async Task DiagnoseAsync_WithEmptyAiResponse_Throws()
    {
        await using var context = CreateContext(nameof(DiagnoseAsync_WithEmptyAiResponse_Throws));
        SetupAiResponse(string.Empty);

        var act = async () => await CreateService(context).DiagnoseAsync(
            new ClinicalDiagnosisRequest("Keto"),
            1);

        await act.Should().ThrowAsync<InvalidOperationException>();
        context.ClinicalDiagnosisReports.Should().BeEmpty();
    }
}
