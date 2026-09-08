using FluentAssertions;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Moq;
using NutriExercise.Api.Controllers;
using NutriExercise.Core.Interfaces;
using NutriExercise.Infrastructure.Data;
using Reqnroll;

namespace NutriExercise.Specs.Steps;

[Binding]
public class DailyLogManagementSteps
{
    private readonly Mock<IAiService> _aiServiceMock = new();
    private readonly Mock<IDailyLogRepository> _dailyLogRepositoryMock = new();
    private LogController? _controller;
    private IActionResult? _result;
    private Guid _deleteId;

    [Given(@"a daily log with id ""(.*)"" exists")]
    public void GivenADailyLogWithIdExists(Guid id)
    {
        _deleteId = id;
        _dailyLogRepositoryMock
            .Setup(r => r.DeleteAsync(id, It.IsAny<CancellationToken>()))
            .ReturnsAsync(true);
    }

    [Given(@"no daily log with id ""(.*)"" exists")]
    public void GivenNoDailyLogWithIdExists(Guid id)
    {
        _deleteId = id;
        _dailyLogRepositoryMock
            .Setup(r => r.DeleteAsync(id, It.IsAny<CancellationToken>()))
            .ReturnsAsync(false);
    }

    [When(@"the user deletes that log")]
    public async Task WhenTheUserDeletesThatLog()
    {
        _controller = new LogController(
            _aiServiceMock.Object,
            _dailyLogRepositoryMock.Object,
            CreateMockDbContext());

        _result = await _controller.Delete(_deleteId);
    }

    [Then(@"the response should return 204 No Content")]
    public void ThenTheResponseShouldReturn204NoContent()
    {
        _result.Should().BeOfType<NoContentResult>();
    }

    [Then(@"the response should return 404 Not Found")]
    public void ThenTheResponseShouldReturn404NotFound()
    {
        _result.Should().BeOfType<NotFoundResult>();
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