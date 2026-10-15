using NutriExercise.Core.DTOs;

namespace NutriExercise.Core.Interfaces;

public interface ILogReaderService
{
    Task<PagedLogResponse> GetLogsAsync(
        LogQuery query,
        CancellationToken cancellationToken = default);
}
