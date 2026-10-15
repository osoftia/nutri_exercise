using Microsoft.Extensions.Logging;
using NutriExercise.Core.Configuration;
using NutriExercise.Core.Interfaces;

namespace NutriExercise.Infrastructure.Logging;

#pragma warning disable CA1848 // Dynamic prefixed tags require runtime-formatted messages.
public class RagLogger : IRagLogger
{
    private readonly ILogger<RagLogger> _logger;

    public RagLogger(ILogger<RagLogger> logger)
    {
        ArgumentNullException.ThrowIfNull(logger);

        _logger = logger;
    }

    public void LogInfo(string message, params object[] args)
    {
        if (string.IsNullOrWhiteSpace(message))
        {
            return;
        }

        _logger.LogInformation(
            "{RagTag} " + message,
            Prepend(RagLogTags.Info, args));
    }

    public void LogError(Exception exception, string message, params object[] args)
    {
        ArgumentNullException.ThrowIfNull(exception);

        if (string.IsNullOrWhiteSpace(message))
        {
            return;
        }

        _logger.LogError(
            exception,
            "{RagTag} " + message,
            Prepend(RagLogTags.Error, args));
    }

    private static object[] Prepend(string tag, object[] args)
    {
        var values = args ?? Array.Empty<object>();
        var buffer = new object[values.Length + 1];
        buffer[0] = tag;
        Array.Copy(values, 0, buffer, 1, values.Length);

        return buffer;
    }
}
#pragma warning restore CA1848
