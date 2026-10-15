using FluentAssertions;
using Microsoft.AspNetCore.Mvc;
using Moq;
using NutriExercise.Api.Controllers;
using NutriExercise.Core.Configuration;
using NutriExercise.Core.DTOs;
using NutriExercise.Core.Entities;
using NutriExercise.Core.Interfaces;

namespace NutriExercise.Tests;

public class ClinicalControllerTests
{
    private readonly Mock<IClinicalDiagnosisService> _serviceMock = new();
    private readonly Mock<IUserRepository> _userRepositoryMock = new();
    private readonly Mock<IRagLogger> _ragLoggerMock = new();

    private ClinicalController CreateController() =>
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
    public async Task Diagnose_WithEmptyPreferences_ReturnsBadRequest()
    {
        var result = await CreateController().Diagnose(new ClinicalDiagnosisRequest("   "));

        result.Should().BeOfType<BadRequestObjectResult>();
        _serviceMock.Verify(
            s => s.DiagnoseAsync(
                It.IsAny<ClinicalDiagnosisRequest>(),
                It.IsAny<int>(),
                It.IsAny<CancellationToken>()),
            Times.Never);
    }

    [Fact]
    public async Task Diagnose_WithValidRequest_ReturnsOkResponse()
    {
        SetupDefaultUser();

        var expected = new ClinicalDiagnosisResponse(
            Guid.NewGuid(),
            DefaultUser.Id,
            "report",
            new List<MealSuggestion>(),
            "llama3-clinical",
            DateTime.UtcNow);

        _serviceMock
            .Setup(s => s.DiagnoseAsync(
                It.IsAny<ClinicalDiagnosisRequest>(),
                DefaultUser.Id,
                It.IsAny<CancellationToken>()))
            .ReturnsAsync(expected);

        var result = await CreateController().Diagnose(
            new ClinicalDiagnosisRequest("Vegetarian", "Anemia"));

        var okResult = result.Should().BeOfType<OkObjectResult>().Subject;
        okResult.Value.Should().BeSameAs(expected);
    }

    [Fact]
    public async Task Diagnose_WithUnknownUser_FallsBackToDefaultUser()
    {
        SetupDefaultUser();

        var result = await CreateController().Diagnose(
            new ClinicalDiagnosisRequest("Keto", null, 999));

        result.Should().BeOfType<OkObjectResult>();
        _userRepositoryMock.Verify(
            r => r.EnsureSeedUserAsync(It.IsAny<CancellationToken>()),
            Times.Once);
    }
}
