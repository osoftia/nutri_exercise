using FluentAssertions;
using Microsoft.EntityFrameworkCore;
using Moq;
using NutriExercise.Core.Configuration;
using NutriExercise.Core.Interfaces;
using NutriExercise.Infrastructure.Data;

namespace NutriExercise.Tests;

public class DbInitializerTests
{
    private readonly Mock<IRagLogger> _ragLoggerMock = new();
    private readonly Mock<IResearchDocumentRepository> _documentsMock = new();
    private readonly Mock<IAiService> _aiServiceMock = new();

    private static AppDbContext CreateContext(string name)
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(name)
            .Options;

        return new AppDbContext(options);
    }

    private DbInitializer CreateInitializer(AppDbContext context)
    {
        var userRepository = new UserRepository(context, _ragLoggerMock.Object);
        var seeder = new BaselineKnowledgeSeeder(
            userRepository,
            _documentsMock.Object,
            _aiServiceMock.Object,
            _ragLoggerMock.Object);

        return new DbInitializer(context, userRepository, seeder, _ragLoggerMock.Object);
    }

    [Fact]
    public async Task InitializeAsync_CreatesSchemaAndSeedsDefaultUser()
    {
        await using var context = CreateContext(nameof(InitializeAsync_CreatesSchemaAndSeedsDefaultUser));
        _documentsMock
            .Setup(r => r.HasDocumentsAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(true);

        await CreateInitializer(context).InitializeAsync();

        context.Users.Should().ContainSingle(user =>
            user.Id == DefaultUser.Id &&
            user.Name == DefaultUser.Name &&
            user.Email == DefaultUser.Email);
    }

    [Fact]
    public async Task InitializeAsync_WhenBaselineSeedingFails_StillCompletes()
    {
        await using var context = CreateContext(nameof(InitializeAsync_WhenBaselineSeedingFails_StillCompletes));
        _documentsMock
            .Setup(r => r.HasDocumentsAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(false);
        _aiServiceMock
            .Setup(a => a.GenerateEmbeddingAsync(It.IsAny<string>(), It.IsAny<CancellationToken>()))
            .ThrowsAsync(new HttpRequestException("Ollama offline"));

        var act = async () => await CreateInitializer(context).InitializeAsync();

        await act.Should().NotThrowAsync();
        context.Users.Should().ContainSingle(user => user.Id == DefaultUser.Id);
        _ragLoggerMock.Verify(
            l => l.LogError(
                It.IsAny<Exception>(),
                It.IsAny<string>(),
                It.IsAny<object[]>()),
            Times.AtLeastOnce);
    }
}
