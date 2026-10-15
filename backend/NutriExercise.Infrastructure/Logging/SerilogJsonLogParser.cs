using System.Globalization;
using System.Text.Json;
using NutriExercise.Core.DTOs;

namespace NutriExercise.Infrastructure.Logging;

/// <summary>
/// Parses a single Serilog <c>JsonFormatter</c> line into a strongly typed
/// <see cref="LogEntryDto"/>. Malformed lines return <c>null</c> so a single
/// corrupt entry never breaks the whole log page.
/// </summary>
public static class SerilogJsonLogParser
{
    public static LogEntryDto? Parse(string line, string sourceFile)
    {
        if (string.IsNullOrWhiteSpace(line))
        {
            return null;
        }

        try
        {
            using var document = JsonDocument.Parse(line);

            return Parse(document.RootElement, sourceFile);
        }
        catch (JsonException)
        {
            return null;
        }
    }

    private static LogEntryDto Parse(JsonElement root, string sourceFile) =>
        new(
            ReadTimestamp(root),
            ReadString(root, "Level") ?? "Unknown",
            ReadString(root, "RenderedMessage") ?? ReadString(root, "MessageTemplate") ?? string.Empty,
            ReadString(root, "Exception"),
            ReadProperties(root),
            sourceFile);

    private static DateTimeOffset ReadTimestamp(JsonElement root)
    {
        var raw = ReadString(root, "Timestamp");

        return DateTimeOffset.TryParse(
            raw,
            CultureInfo.InvariantCulture,
            DateTimeStyles.RoundtripKind,
            out var timestamp)
            ? timestamp
            : DateTimeOffset.MinValue;
    }

    private static string? ReadString(JsonElement root, string propertyName) =>
        root.TryGetProperty(propertyName, out var value) && value.ValueKind == JsonValueKind.String
            ? value.GetString()
            : null;

    private static IReadOnlyDictionary<string, string> ReadProperties(JsonElement root)
    {
        var properties = new Dictionary<string, string>(StringComparer.Ordinal);

        if (!root.TryGetProperty("Properties", out var source) || source.ValueKind != JsonValueKind.Object)
        {
            return properties;
        }

        foreach (var property in source.EnumerateObject())
        {
            properties[property.Name] = property.Value.ValueKind == JsonValueKind.String
                ? property.Value.GetString() ?? string.Empty
                : property.Value.ToString();
        }

        return properties;
    }
}
