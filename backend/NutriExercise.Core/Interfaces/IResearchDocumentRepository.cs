using NutriExercise.Core.Entities;

namespace NutriExercise.Core.Interfaces;

public interface IResearchDocumentRepository
{
    Task AddDocumentAsync(ResearchDocument document, CancellationToken cancellationToken = default);

    Task<bool> HasDocumentsAsync(CancellationToken cancellationToken = default);

    Task<List<ResearchDocument>> SearchSimilarDocumentsAsync(float[] queryVector, int limit = 2, CancellationToken cancellationToken = default);
}
