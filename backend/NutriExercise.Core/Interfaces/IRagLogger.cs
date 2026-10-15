namespace NutriExercise.Core.Interfaces;

public interface IRagLogger
{
    void LogInfo(string message, params object[] args);

    void LogError(Exception exception, string message, params object[] args);
}
