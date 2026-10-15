using NutriExercise.Core.DTOs;

namespace NutriExercise.Core.Interfaces;

public interface IClinicalMenuService
{
    Task<ClinicalMenuResponse> GenerateAsync(
        ClinicalMenuRequest request,
        int userId,
        CancellationToken cancellationToken = default);
}
