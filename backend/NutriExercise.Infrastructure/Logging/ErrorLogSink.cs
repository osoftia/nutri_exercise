using Microsoft.EntityFrameworkCore;
using NutriExercise.Core.Entities;
using NutriExercise.Infrastructure.Data;
using Serilog.Core;
using Serilog.Events;

namespace NutriExercise.Infrastructure.Logging;

public class ErrorLogSink : ILogEventSink
{
    private readonly DbContextOptions<AppDbContext> _options;

    public ErrorLogSink(DbContextOptions<AppDbContext> options)
    {
        _options = options;
    }

    public void Emit(LogEvent logEvent)
    {
        ArgumentNullException.ThrowIfNull(logEvent);

        if (logEvent.Level < LogEventLevel.Error)
        {
            return;
        }

        try
        {
            using var context = new AppDbContext(_options);
            context.ErrorLogs.Add(new ErrorLog
            {
                Timestamp = logEvent.Timestamp.UtcDateTime,
                Message = logEvent.RenderMessage(),
                StackTrace = logEvent.Exception?.ToString(),
                Module = logEvent.Properties.TryGetValue("SourceContext", out var source)
                    ? source.ToString().Trim('"')
                    : "Application"
            });
            context.SaveChanges();
        }
        catch
        {
            // Never let logging infrastructure break the application.
        }
    }
}