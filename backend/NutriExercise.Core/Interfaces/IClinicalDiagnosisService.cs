using NutriExercise.Core.DTOs;

namespace NutriExercise.Core.Interfaces;

public interface IClinicalDiagnosisService
{
    Task<ClinicalDiagnosisResponse> DiagnoseAsync(
        ClinicalDiagnosisRequest request,
        int userId,
        CancellationToken cancellationToken = default);
}
