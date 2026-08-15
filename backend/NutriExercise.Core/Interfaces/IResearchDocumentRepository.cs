using NutriExercise.Core.Entities;

namespace NutriExercise.Core.Interfaces;

public interface IResearchDocumentRepository
{
    Task AddDocumentAsync(ResearchDocument document, CancellationToken cancellationToken = default);
}
