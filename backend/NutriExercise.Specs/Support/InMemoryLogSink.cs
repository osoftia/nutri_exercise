using Serilog.Core;
using Serilog.Events;

namespace NutriExercise.Specs.Support;

public sealed class InMemoryLogSink : ILogEventSink
{
    private readonly List<LogEvent> _events = new();

    public IReadOnlyList<LogEvent> Events => _events;

    public void Emit(LogEvent logEvent)
    {
        ArgumentNullException.ThrowIfNull(logEvent);

        _events.Add(logEvent);
    }
}
