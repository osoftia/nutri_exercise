using FluentAssertions;
using Microsoft.EntityFrameworkCore;
using Moq;
using NutriExercise.Core.Configuration;
using NutriExercise.Core.Interfaces;
using NutriExercise.Infrastructure.Data;

namespace NutriExercise.Tests;

public class UserRepositoryTests
{
    private readonly Mock<IRagLogger> _ragLoggerMock = new();

    private static AppDbContext CreateContext(string name)
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(name)
            .Options;

        return new AppDbContext(options);
    }

    [Fact]
    public async Task EnsureSeedUserAsync_WhenMissing_CreatesDefaultTestUser()
    {
        await using var context = CreateContext(nameof(EnsureSeedUserAsync_WhenMissing_CreatesDefaultTestUser));
        var repository = new UserRepository(context, _ragLoggerMock.Object);

        var user = await repository.EnsureSeedUserAsync();

        user.Id.Should().Be(DefaultUser.Id);
        user.Name.Should().Be(DefaultUser.Name);
        user.Email.Should().Be(DefaultUser.Email);
        context.Users.Should().ContainSingle();
    }

    [Fact]
    public async Task EnsureSeedUserAsync_WhenCalledTwice_IsIdempotent()
    {
        await using var context = CreateContext(nameof(EnsureSeedUserAsync_WhenCalledTwice_IsIdempotent));
        var repository = new UserRepository(context, _ragLoggerMock.Object);

        await repository.EnsureSeedUserAsync();
        await repository.EnsureSeedUserAsync();

        context.Users.Should().ContainSingle();
    }

    [Fact]
    public async Task EnsureSeedUserAsync_WhenCreated_LogsSeedingInfo()
    {
        await using var context = CreateContext(nameof(EnsureSeedUserAsync_WhenCreated_LogsSeedingInfo));
        var repository = new UserRepository(context, _ragLoggerMock.Object);

        await repository.EnsureSeedUserAsync();

        _ragLoggerMock.Verify(
            l => l.LogInfo(
                It.IsAny<string>(),
                It.IsAny<object[]>()),
            Times.Once);
    }

    [Fact]
    public async Task GetByIdAsync_WithUnknownId_ReturnsNull()
    {
        await using var context = CreateContext(nameof(GetByIdAsync_WithUnknownId_ReturnsNull));
        var repository = new UserRepository(context, _ragLoggerMock.Object);

        var user = await repository.GetByIdAsync(999);

        user.Should().BeNull();
    }
}
