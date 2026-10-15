namespace NutriExercise.Core.Configuration;

public class LogReaderSettings
{
    public const string SectionName = "LogReader";

    public string Directory { get; set; } = "Logs";

    public string FileSearchPattern { get; set; } = "nutriexercise-*.json";

    public int DefaultPageSize { get; set; } = 50;

    public int MaxPageSize { get; set; } = 200;
}
