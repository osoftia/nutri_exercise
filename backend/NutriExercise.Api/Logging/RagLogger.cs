namespace NutriExercise.Api.Logging;

/// <summary>
/// Structured logging helpers for the RAG feature.
///
/// Every message is explicitly prefixed so log scrapers can trace the
/// feature without parsing levels:
/// <list type="bullet">
/// <item><c>[RAG-INFO]:</c> — successful queries, model throughput telemetry,
/// successful vector insertions, database seeding events.</item>
/// <item><c>[RAG-ERROR]:</c> — pgvector exceptions, database connectivity
/// failures, internal processing errors.</item>
/// </list>
/// </summary>
public static class RagLogger
{
    public const string InfoPrefix = "[RAG-INFO]:";
    public const string ErrorPrefix = "[RAG-ERROR]:";

    public static void LogRagInfo(this ILogger logger, string message, params object?[] args)
    {
        logger.LogInformation($"{InfoPrefix} {message}", args);
    }

    public static void LogRagInfo<T>(this ILogger<T> logger, string message, params object?[] args)
    {
        LogRagInfo((ILogger)logger, message, args);
    }

    public static void LogRagError(this ILogger logger, Exception exception, string message, params object?[] args)
    {
        logger.LogError(exception, $"{ErrorPrefix} {message}", args);
    }

    public static void LogRagError<T>(this ILogger<T> logger, Exception exception, string message, params object?[] args)
    {
        LogRagError((ILogger)logger, exception, message, args);
    }

    public static void LogRagError(this ILogger logger, string message, params object?[] args)
    {
        logger.LogError($"{ErrorPrefix} {message}", args);
    }

    public static void LogRagError<T>(this ILogger<T> logger, string message, params object?[] args)
    {
        LogRagError((ILogger)logger, message, args);
    }
}
