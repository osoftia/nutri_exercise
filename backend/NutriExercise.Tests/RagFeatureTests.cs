using Microsoft.Extensions.Logging;
using NutriExercise.Api.DTOs;
using NutriExercise.Api.Logging;
using NutriExercise.Core.Constants;
using NutriExercise.Core.Entities;

namespace NutriExercise.Tests;

public class RagFeatureTests
{
    [Fact]
    public void RagDefaults_Exposes_Seeded_Test_User()
    {
        Assert.Equal(1, RagDefaults.DefaultUserId);
        Assert.Equal("Test User", RagDefaults.DefaultUserName);
        Assert.Equal("test@nutriexercise.local", RagDefaults.DefaultUserEmail);
    }

    [Theory]
    [InlineData(null, 1)]
    [InlineData(0, 1)]
    [InlineData(-3, 1)]
    [InlineData(1, 1)]
    [InlineData(7, 7)]
    public void ResolveUserId_Falls_Back_To_Default_For_Missing_Or_Invalid(int? candidate, int expected)
    {
        Assert.Equal(expected, RagDefaults.ResolveUserId(candidate));
    }

    [Fact]
    public void IngestRequest_Defaults_To_UserId_1_Without_Auth_Token()
    {
        var request = new RagIngestRequest { Title = "T", Content = "C", BodyZone = "Chest", UserId = 42 };

        Assert.Equal(1, request.ResolveUserId(hasAuthToken: false));
        Assert.Equal(42, request.ResolveUserId(hasAuthToken: true));
    }

    [Fact]
    public void QueryRequest_Defaults_To_UserId_1_Without_Auth_Token()
    {
        var request = new RagQueryRequest { Query = "q", UserId = null };

        Assert.Equal(1, request.ResolveUserId(hasAuthToken: false));
        Assert.Equal(1, request.ResolveUserId(hasAuthToken: true));
    }

    [Fact]
    public void Entities_Default_Ownership_To_Test_User()
    {
        Assert.Equal(1, new ResearchDocument().UserId);
        Assert.Equal(1, new AiInteraction().UserId);
        Assert.Equal(string.Empty, new ResearchDocument().BodyZone);
    }

    [Fact]
    public void RagLogger_Info_Emits_Rag_Info_Prefix()
    {
        var sink = new CapturingLogger();

        sink.LogRagInfo("query executed successfully for UserId = {UserId}.", 1);

        Assert.Single(sink.Messages);
        Assert.StartsWith("[RAG-INFO]:", sink.Messages[0]);
        Assert.Contains("query executed successfully", sink.Messages[0]);
    }

    [Fact]
    public void RagLogger_Error_Emits_Rag_Error_Prefix()
    {
        var sink = new CapturingLogger();

        sink.LogRagError(new InvalidOperationException("boom"), "pgvector exception while ingesting.");
        sink.LogRagError("database connectivity failure.");

        Assert.Equal(2, sink.Messages.Count);
        Assert.All(sink.Messages, m => Assert.StartsWith("[RAG-ERROR]:", m));
    }

    private sealed class CapturingLogger : ILogger
    {
        public List<string> Messages { get; } = new();

        IDisposable ILogger.BeginScope<TState>(TState state) => NullScope.Instance;

        bool ILogger.IsEnabled(LogLevel logLevel) => true;

        void ILogger.Log<TState>(LogLevel logLevel, EventId eventId, TState state, Exception? exception, Func<TState, Exception?, string> formatter)
        {
            Messages.Add(formatter(state, exception));
        }

        private sealed class NullScope : IDisposable
        {
            public static readonly NullScope Instance = new();
            public void Dispose() { }
        }
    }
}
