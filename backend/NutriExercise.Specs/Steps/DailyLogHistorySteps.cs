using FluentAssertions;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Moq;
using NutriExercise.Api.Controllers;
using NutriExercise.Core.Entities;
using NutriExercise.Core.Interfaces;
using NutriExercise.Infrastructure.Data;
using Reqnroll;

namespace NutriExercise.Specs.Steps;

[Binding]
public class DailyLogHistorySteps
{
    private readonly Mock<IAiService> _aiServiceMock = new();
    private readonly Mock<IDailyLogRepository> _dailyLogRepositoryMock = new();
    private LogController? _controller;
    private IActionResult? _result;
    private List<DailyLogRecord> _logs = new();

    [Given(@"the database contains (\d+) saved daily logs")]
    public void GivenTheDatabaseContainsSavedDailyLogs(int count)
    {
        _logs = Enumerable.Range(1, count).Select(i => new DailyLogRecord
        {
            Id = Guid.NewGuid(),
            OriginalText = $"Log {i}",
            Calories = 300 + i,
            Protein = 20,
            Carbs = 30,
            Fats = 10,
            MuscleGroups = "Chest"
        }).ToList();
    }

    [Given(@"the database contains a log created today")]
    public void GivenTheDatabaseContainsALogCreatedToday()
    {
        _logs.Add(new DailyLogRecord
        {
            Id = Guid.NewGuid(),
            CreatedAt = DateTime.UtcNow,
            OriginalText = "Today log",
            Calories = 300,
            Protein = 20,
            Carbs = 30,
            Fats = 10,
            MuscleGroups = "Chest"
        });
    }

    [Given(@"the database contains a log created yesterday")]
    public void GivenTheDatabaseContainsALogCreatedYesterday()
    {
        _logs.Add(new DailyLogRecord
        {
            Id = Guid.NewGuid(),
            CreatedAt = DateTime.UtcNow.AddDays(-1),
            OriginalText = "Yesterday log",
            Calories = 400,
            Protein = 25,
            Carbs = 40,
            Fats = 12,
            MuscleGroups = "Back"
        });
    }

    [Given(@"the database contains a log from ""(.*)""")]
    public void GivenTheDatabaseContainsALogFrom(DateTime date)
    {
        _logs.Add(new DailyLogRecord
        {
            Id = Guid.NewGuid(),
            CreatedAt = date,
            OriginalText = $"Log from {date:yyyy-MM-dd}",
            Calories = 500,
            Protein = 30,
            Carbs = 50,
            Fats = 15,
            MuscleGroups = "Legs"
        });
    }

    [When(@"the user requests the daily log history")]
    public async Task WhenTheUserRequestsTheDailyLogHistory()
    {
        _dailyLogRepositoryMock
            .Setup(r => r.GetAllAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(_logs);

        _controller = new LogController(
            _aiServiceMock.Object,
            _dailyLogRepositoryMock.Object,
            CreateMockDbContext());

        _result = await _controller.GetHistory();
    }

    [When(@"the user requests logs between ""(.*)"" and ""(.*)""")]
    public async Task WhenTheUserRequestsLogsBetween(DateTime from, DateTime to)
    {
        _dailyLogRepositoryMock
            .Setup(r => r.GetAllAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(_logs);

        _controller = new LogController(
            _aiServiceMock.Object,
            _dailyLogRepositoryMock.Object,
            CreateMockDbContext());

        _result = await _controller.GetHistory(sort: "desc", from: from, to: to);
    }

    [Then(@"the response should return 200 OK")]
    public void ThenTheResponseShouldReturn200Ok()
    {
        _result.Should().BeOfType<OkObjectResult>();
    }

    [Then(@"the response should contain (\d+) logs")]
    public void ThenTheResponseShouldContainLogs(int count)
    {
        var ok = _result as OkObjectResult;
        var logs = ok!.Value as IEnumerable<DailyLogRecord>;
        logs.Should().HaveCount(count);
    }

    [Then(@"each log should include calories, protein, carbs, fats, and muscle groups")]
    public void ThenEachLogShouldIncludeAllFields()
    {
        var ok = _result as OkObjectResult;
        var logs = ok!.Value as IEnumerable<DailyLogRecord>;
        logs!.Should().OnlyContain(l =>
            l.Calories > 0 && l.Protein > 0 && l.Carbs > 0 && l.Fats > 0 &&
            !string.IsNullOrEmpty(l.MuscleGroups));
    }

    [Then(@"the first log in the response should be the one created today")]
    public void ThenTheFirstLogInTheResponseShouldBeTheOneCreatedToday()
    {
        var ok = _result as OkObjectResult;
        var logs = ok!.Value as IEnumerable<DailyLogRecord>;
        logs!.First().OriginalText.Should().Be("Today log");
    }

    [Then(@"the response should contain only the log from ""(.*)""")]
    public void ThenTheResponseShouldContainOnlyTheLogFrom(DateTime date)
    {
        var ok = _result as OkObjectResult;
        var logs = ok!.Value as IEnumerable<DailyLogRecord>;
        logs!.Should().ContainSingle();
        logs!.Single().CreatedAt.Should().Be(date);
    }

    private static AppDbContext CreateMockDbContext()
    {
        var dbContextMock = new Mock<AppDbContext>(new DbContextOptions<AppDbContext>());
        dbContextMock
            .Setup(c => c.SaveChangesAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(1);

        return dbContextMock.Object;
    }
}