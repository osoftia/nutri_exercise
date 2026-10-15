using FluentAssertions;
using Microsoft.Extensions.Logging;
using NutriExercise.Core.Configuration;
using NutriExercise.Infrastructure.Logging;

namespace NutriExercise.Tests;

public class RagLoggerTests
{
    private static (RagLogger Logger, CapturingLogger Capture) CreateLogger()
    {
        var capture = new CapturingLogger();
        var logger = new RagLogger(capture);

        return (logger, capture);
    }

    [Fact]
    public void LogInfo_PrefixesMessageWithRagInfoTag()
    {
        var (logger, capture) = CreateLogger();

        logger.LogInfo("Query executed. UserId={UserId}.", 1);

        capture.LastMessage.Should().StartWith(RagLogTags.Info);
        capture.LastMessage.Should().Contain("Query executed.");
        capture.LastLevel.Should().Be(LogLevel.Information);
    }

    [Fact]
    public void LogError_PrefixesMessageWithRagErrorTagAndIncludesException()
    {
        var (logger, capture) = CreateLogger();
        var exception = new InvalidOperationException("pgvector offline");

        logger.LogError(exception, "Vector search failed.");

        capture.LastMessage.Should().StartWith(RagLogTags.Error);
        capture.LastMessage.Should().Contain("Vector search failed.");
        capture.LastException.Should().BeSameAs(exception);
        capture.LastLevel.Should().Be(LogLevel.Error);
    }

    [Fact]
    public void LogError_WithNullException_ThrowsArgumentNullException()
    {
        var (logger, _) = CreateLogger();

        var act = () => logger.LogError(null!, "message");

        act.Should().Throw<ArgumentNullException>();
    }

    private sealed class CapturingLogger : ILogger<RagLogger>
    {
        public LogLevel LastLevel { get; private set; }

        public string LastMessage { get; private set; } = string.Empty;

        public Exception? LastException { get; private set; }

        public IDisposable? BeginScope<TState>(TState state)
            where TState : notnull
        {
            return null;
        }

        public bool IsEnabled(LogLevel logLevel) => true;

        public void Log<TState>(
            LogLevel logLevel,
            EventId eventId,
            TState state,
            Exception? exception,
            Func<TState, Exception?, string> formatter)
        {
            LastLevel = logLevel;
            LastException = exception;
            LastMessage = formatter(state, exception);
        }
    }
}
