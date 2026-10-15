using NutriExercise.Core.Configuration;
using NutriExercise.Core.Entities;
using NutriExercise.Core.Interfaces;
using Pgvector;

namespace NutriExercise.Infrastructure.Data;

public class BaselineKnowledgeSeeder
{
    private readonly IUserRepository _userRepository;
    private readonly IResearchDocumentRepository _researchDocumentRepository;
    private readonly IAiService _aiService;
    private readonly IRagLogger _ragLogger;

    public BaselineKnowledgeSeeder(
        IUserRepository userRepository,
        IResearchDocumentRepository researchDocumentRepository,
        IAiService aiService,
        IRagLogger ragLogger)
    {
        ArgumentNullException.ThrowIfNull(userRepository);
        ArgumentNullException.ThrowIfNull(researchDocumentRepository);
        ArgumentNullException.ThrowIfNull(aiService);
        ArgumentNullException.ThrowIfNull(ragLogger);

        _userRepository = userRepository;
        _researchDocumentRepository = researchDocumentRepository;
        _aiService = aiService;
        _ragLogger = ragLogger;
    }

    public async Task SeedAsync(CancellationToken cancellationToken = default)
    {
        if (await _researchDocumentRepository.HasDocumentsAsync(cancellationToken))
        {
            _ragLogger.LogInfo("Baseline vector data already present. Skipping seed.");
            return;
        }

        var user = await _userRepository.EnsureSeedUserAsync(cancellationToken);
        var seeded = 0;

        foreach (var document in BaselineKnowledge.Documents)
        {
            seeded += await TrySeedDocumentAsync(document, user.Id, cancellationToken);
        }

        _ragLogger.LogInfo(
            "Baseline vector seeding complete. Seeded={Seeded}, Total={Total}.",
            seeded,
            BaselineKnowledge.Documents.Count);
    }

    private async Task<int> TrySeedDocumentAsync(
        BaselineKnowledgeDocument document,
        int userId,
        CancellationToken cancellationToken)
    {
        var embedding = await _aiService.GenerateEmbeddingAsync(
            document.Content,
            cancellationToken);

        if (embedding.Length == 0)
        {
            _ragLogger.LogError(
                new InvalidOperationException("Embedding model returned no vector."),
                "Baseline embedding generation returned no vector. Title={Title}.",
                document.Title);

            return 0;
        }

        await _researchDocumentRepository.AddDocumentAsync(
            new ResearchDocument
            {
                Id = Guid.NewGuid(),
                Title = document.Title,
                Content = document.Content,
                Source = document.Source,
                BodyZone = "General",
                UserId = userId,
                Embedding = new Vector(embedding)
            },
            cancellationToken);

        _ragLogger.LogInfo(
            "Baseline vector inserted. Title={Title}, UserId={UserId}, Dimensions={Dimensions}.",
            document.Title,
            userId,
            embedding.Length);

        return 1;
    }
}
