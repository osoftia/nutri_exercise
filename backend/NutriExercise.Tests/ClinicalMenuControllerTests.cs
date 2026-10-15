using FluentAssertions;
using Microsoft.AspNetCore.Mvc;
using Moq;
using NutriExercise.Api.Controllers;
using NutriExercise.Core.Configuration;
using NutriExercise.Core.DTOs;
using NutriExercise.Core.Entities;
using NutriExercise.Core.Interfaces;

namespace NutriExercise.Tests;

public class ClinicalMenuControllerTests
{
    private readonly Mock<IClinicalMenuService> _serviceMock = new();
    private readonly Mock<IUserRepository> _userRepositoryMock = new();
    private readonly Mock<IRagLogger> _ragLoggerMock = new();

    private ClinicalMenuController CreateController() =>
        new(_serviceMock.Object, _userRepositoryMock.Object, _ragLoggerMock.Object);

    private void SetupDefaultUser()
    {
        _userRepositoryMock
            .Setup(r => r.EnsureSeedUserAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(new User
            {
                Id = DefaultUser.Id,
                Name = DefaultUser.Name,
                Email = DefaultUser.Email
            });
    }

    [Fact]
    public async Task Generate_WithEmptyCondition_ReturnsBadRequest()
    {
        var result = await CreateController().Generate(new ClinicalMenuRequest("  "));

        result.Should().BeOfType<BadRequestObjectResult>();
        _serviceMock.Verify(
            s => s.GenerateAsync(
                It.IsAny<ClinicalMenuRequest>(),
                It.IsAny<int>(),
                It.IsAny<CancellationToken>()),
            Times.Never);
    }

    [Fact]
    public async Task Generate_WithValidRequest_ReturnsOkResponse()
    {
        SetupDefaultUser();

        var expected = new ClinicalMenuResponse(
            Guid.NewGuid(),
            DefaultUser.Id,
            "Gout",
            new List<string> { "Gout" },
            new GuardrailSummary(new List<string>(), new List<string>(), new List<ConditionGuardrail>()),
            new ClinicalMenuContent("plan", new List<ClinicalMealItem>(), new List<ClinicalExerciseItem>()),
            "llama3-clinical-menu",
            DateTime.UtcNow);

        _serviceMock
            .Setup(s => s.GenerateAsync(
                It.IsAny<ClinicalMenuRequest>(),
                DefaultUser.Id,
                It.IsAny<CancellationToken>()))
            .ReturnsAsync(expected);

        var result = await CreateController().Generate(
            new ClinicalMenuRequest("Gout", "Joint pain"));

        var okResult = result.Should().BeOfType<OkObjectResult>().Subject;
        okResult.Value.Should().BeSameAs(expected);
    }

    [Fact]
    public async Task Generate_WithUnknownUser_FallsBackToDefaultUser()
    {
        SetupDefaultUser();

        var result = await CreateController().Generate(
            new ClinicalMenuRequest("Diabetes", null, 999));

        result.Should().BeOfType<OkObjectResult>();
        _userRepositoryMock.Verify(
            r => r.EnsureSeedUserAsync(It.IsAny<CancellationToken>()),
            Times.Once);
    }
}
