using System.Linq.Expressions;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Query;
using Moq;
using Reqnroll;
using FluentAssertions;
using Microsoft.AspNetCore.Mvc;
using NutriExercise.Api.Controllers;
using NutriExercise.Core.Entities;
using NutriExercise.Core.Interfaces;
using NutriExercise.Infrastructure.Data;

namespace NutriExercise.Specs.Steps;

[Binding]
public class RoutineGenerationSteps
{
    private readonly Mock<IAiService> _aiServiceMock = new();
    private readonly Mock<IResearchDocumentRepository> _documentRepositoryMock = new();
    private readonly Mock<IRoutineRepository> _routineRepositoryMock = new();
    private AppDbContext? _dbContext;
    private RoutineController? _controller;
    private IActionResult? _result;
    private string? _capturedPrompt;

    [Given(@"the scientific database contains a document about ""(.*)""")]
    public void GivenTheScientificDatabaseContainsDocument(string content)
    {
        var docs = new List<ResearchDocument>
        {
            new() { Id = Guid.NewGuid(), Title = "Hypertrophy Study", Content = content, Source = "study" }
        };

        _documentRepositoryMock
            .Setup(r => r.SearchSimilarDocumentsAsync(It.IsAny<float[]>(), It.IsAny<int>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(docs);
    }

    [Given(@"the LLM is configured to return strict JSON format")]
    public void GivenTheLlmIsConfiguredToReturnStrictJson()
    {
        const string json =
            "{\"routineName\":\"Fuerza Total\"," +
            "\"summary\":\"Estrategia basada en contexto\"," +
            "\"exercises\":[{\"name\":\"Press Banca\",\"sets\":4,\"reps\":\"8-12\",\"rest\":\"90 segundos\",\"notes\":\"Técnica\"}]," +
            "\"nutritionAdvice\":\"Proteína adecuada\"}";

        _aiServiceMock
            .Setup(s => s.GenerateRoutineAsync(It.IsAny<string>(), It.IsAny<CancellationToken>()))
            .Callback<string, CancellationToken>((prompt, _) => _capturedPrompt = prompt)
            .ReturnsAsync(json);

        _aiServiceMock
            .Setup(s => s.GenerateEmbeddingAsync(It.IsAny<string>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(new float[] { 0.1f, 0.2f, 0.3f });
    }

    [When(@"the user requests a routine for ""(.*)""")]
    public async Task WhenTheUserRequestsARoutine(string preference)
    {
        _dbContext = CreateMockDbContext();
        _controller = new RoutineController(
            _aiServiceMock.Object,
            _routineRepositoryMock.Object,
            _documentRepositoryMock.Object,
            _dbContext);

        _result = await _controller.Generate(new GenerateRoutineRequest { UserPreferences = preference });
    }

    [Then(@"the augmented prompt must include the scientific context")]
    public void ThenTheAugmentedPromptMustIncludeTheScientificContext()
    {
        _capturedPrompt.Should().NotBeNull("the AI service must be invoked with a prompt");
        _capturedPrompt!.Should().Contain("Hypertrophy and 10 weekly sets");
        _capturedPrompt.Should().Contain("ganar masa muscular");
        _capturedPrompt.Should().Contain("REGLA ESTRICTA");
    }

    [Then(@"the result must be a valid JSON containing a list of exercises")]
    public void ThenTheResultMustBeValidJsonContainingAListOfExercises()
    {
        _result.Should().BeOfType<OkObjectResult>();

        var okResult = _result as OkObjectResult;
        var value = okResult!.Value;

        var routine = value?.GetType().GetProperty("Routine")?.GetValue(value) as Routine;
        routine.Should().NotBeNull();
        routine!.Description.Should().NotBeNullOrEmpty();

        var json = System.Text.Json.JsonSerializer.Deserialize<Dictionary<string, object>>(routine.Description);
        json.Should().NotBeNull();
        json!.Should().ContainKey("routineName");
        json.Should().ContainKey("summary");
        json.Should().ContainKey("exercises");
        json.Should().ContainKey("nutritionAdvice");
        json["exercises"].Should().NotBeNull();
    }

    private static AppDbContext CreateMockDbContext()
    {
        var data = new List<AiInteraction>();

        var dbSetMock = new Mock<DbSet<AiInteraction>>();
        dbSetMock
            .Setup(d => d.Add(It.IsAny<AiInteraction>()))
            .Callback<AiInteraction>(data.Add);

        var dbContextMock = new Mock<AppDbContext>(new DbContextOptions<AppDbContext>());
        dbContextMock.Setup(c => c.AiInteractions).Returns(dbSetMock.Object);
        dbContextMock
            .Setup(c => c.SaveChangesAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(1);

        return dbContextMock.Object;
    }
}
