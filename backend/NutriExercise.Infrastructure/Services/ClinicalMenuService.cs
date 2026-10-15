using System.Diagnostics;
using NutriExercise.Core.DTOs;
using NutriExercise.Core.Interfaces;
using NutriExercise.Infrastructure.Data;

namespace NutriExercise.Infrastructure.Services;

public class ClinicalMenuService : IClinicalMenuService
{
    private const string ModelUsed = "llama3-clinical-menu";
    private const double SimilarityThreshold = 0.45;
    private const double Temperature = 0.3;

    private readonly IVectorSearchService _vectorSearchService;
    private readonly IAiModelService _aiModelService;
    private readonly IClinicalGuardrailService _guardrailService;
    private readonly ClinicalMenuStore _menuStore;
    private readonly IRagLogger _ragLogger;

    public ClinicalMenuService(
        IVectorSearchService vectorSearchService,
        IAiModelService aiModelService,
        IClinicalGuardrailService guardrailService,
        ClinicalMenuStore menuStore,
        IRagLogger ragLogger)
    {
        ArgumentNullException.ThrowIfNull(vectorSearchService);
        ArgumentNullException.ThrowIfNull(aiModelService);
        ArgumentNullException.ThrowIfNull(guardrailService);
        ArgumentNullException.ThrowIfNull(menuStore);
        ArgumentNullException.ThrowIfNull(ragLogger);

        _vectorSearchService = vectorSearchService;
        _aiModelService = aiModelService;
        _guardrailService = guardrailService;
        _menuStore = menuStore;
        _ragLogger = ragLogger;
    }

    public async Task<ClinicalMenuResponse> GenerateAsync(
        ClinicalMenuRequest request,
        int userId,
        CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(request);

        var conditions = ClinicalMenuPrompt.SplitConditions(request.Condition);
        var guardrails = _guardrailService.Evaluate(conditions);

        await _menuStore.SaveSymptomLogAsync(
            request,
            conditions,
            userId,
            cancellationToken);

        var contexts = await RetrieveContextsAsync(request, conditions, cancellationToken);
        var generatedText = await GenerateMenuTextAsync(
            request,
            guardrails,
            contexts,
            cancellationToken);

        if (string.IsNullOrWhiteSpace(generatedText))
        {
            throw new InvalidOperationException(
                "The AI service returned an empty clinical menu.");
        }

        var menu = ClinicalMenuParser.Parse(generatedText, _ragLogger);
        var plan = await _menuStore.SavePlanAsync(
            request,
            userId,
            menu,
            ModelUsed,
            cancellationToken);

        return new ClinicalMenuResponse(
            plan.Id,
            userId,
            request.Condition,
            conditions,
            guardrails,
            menu,
            plan.ModelUsed,
            plan.CreatedAt);
    }

    private async Task<IReadOnlyList<string>> RetrieveContextsAsync(
        ClinicalMenuRequest request,
        IReadOnlyList<string> conditions,
        CancellationToken cancellationToken)
    {
        var query = ClinicalMenuPrompt.BuildRetrievalQuery(request, conditions);

        var contexts = await _vectorSearchService.SearchAsync(
            query,
            SimilarityThreshold,
            cancellationToken);

        _ragLogger.LogInfo(
            "Clinical RAG retrieval complete. Query={Query}, Contexts={ContextCount}.",
            query,
            contexts.Count);

        return contexts;
    }

    private async Task<string> GenerateMenuTextAsync(
        ClinicalMenuRequest request,
        GuardrailSummary guardrails,
        IReadOnlyList<string> contexts,
        CancellationToken cancellationToken)
    {
        var stopwatch = Stopwatch.StartNew();

        var generatedText = await _aiModelService.GenerateAsync(
            ClinicalMenuPrompt.SystemPrompt,
            ClinicalMenuPrompt.BuildUserQuery(request, guardrails),
            contexts,
            Temperature,
            cancellationToken);

        stopwatch.Stop();

        _ragLogger.LogInfo(
            "LLM throughput. Characters={CharacterCount}, LatencyMs={LatencyMs}.",
            generatedText.Length,
            stopwatch.ElapsedMilliseconds);

        return generatedText;
    }
}
