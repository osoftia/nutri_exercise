using System.Text.Json;
using NutriExercise.Core.DTOs;
using NutriExercise.Core.Entities;
using NutriExercise.Core.Interfaces;
using NutriExercise.Infrastructure.Data;

namespace NutriExercise.Infrastructure.Services;

public class ClinicalDiagnosisService : IClinicalDiagnosisService
{
    private const string ModelUsed = "llama3-clinical";
    private const double Temperature = 0.2;

    private const string SystemPrompt =
        "You are a clinical nutrition assistant. Based on the user's food preferences and " +
        "medical conditions, produce a concise diagnostic report and a meal plan. " +
        "Respond ONLY with a valid JSON object using this exact structure and no extra text: " +
        "{\"diagnosticReport\":\"...\",\"mealSuggestions\":" +
        "[{\"mealType\":\"Breakfast\",\"name\":\"...\",\"description\":\"...\"}]}";

    private static readonly JsonSerializerOptions SerializerOptions = new()
    {
        PropertyNameCaseInsensitive = true
    };

    private readonly IAiModelService _aiModelService;
    private readonly AppDbContext _context;
    private readonly IRagLogger _ragLogger;

    public ClinicalDiagnosisService(
        IAiModelService aiModelService,
        AppDbContext context,
        IRagLogger ragLogger)
    {
        ArgumentNullException.ThrowIfNull(aiModelService);
        ArgumentNullException.ThrowIfNull(context);
        ArgumentNullException.ThrowIfNull(ragLogger);

        _aiModelService = aiModelService;
        _context = context;
        _ragLogger = ragLogger;
    }

    public async Task<ClinicalDiagnosisResponse> DiagnoseAsync(
        ClinicalDiagnosisRequest request,
        int userId,
        CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(request);

        _ragLogger.LogInfo(
            "Clinical AI generation started. UserId={UserId}, Model={Model}.",
            userId,
            ModelUsed);

        var generatedText = await _aiModelService.GenerateAsync(
            SystemPrompt,
            BuildUserQuery(request),
            Array.Empty<string>(),
            Temperature,
            cancellationToken);

        if (string.IsNullOrWhiteSpace(generatedText))
        {
            throw new InvalidOperationException(
                "The AI service returned an empty clinical diagnosis.");
        }

        var payload = ParsePayload(generatedText);
        var report = BuildReport(request, userId, payload);

        _context.ClinicalDiagnosisReports.Add(report);
        await _context.SaveChangesAsync(cancellationToken);

        _ragLogger.LogInfo(
            "Clinical diagnosis persisted. ReportId={ReportId}, UserId={UserId}, Meals={MealCount}.",
            report.Id,
            userId,
            payload.MealSuggestions.Count);

        return new ClinicalDiagnosisResponse(
            report.Id,
            userId,
            report.DiagnosticReport,
            payload.MealSuggestions,
            report.ModelUsed,
            report.CreatedAt);
    }

    private static ClinicalDiagnosisReport BuildReport(
        ClinicalDiagnosisRequest request,
        int userId,
        ClinicalAiPayload payload) =>
        new()
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            Preferences = request.Preferences,
            Conditions = request.Conditions ?? string.Empty,
            DiagnosticReport = payload.DiagnosticReport,
            MealSuggestions = JsonSerializer.Serialize(payload.MealSuggestions),
            ModelUsed = ModelUsed,
            CreatedAt = DateTime.UtcNow
        };

    private ClinicalAiPayload ParsePayload(string generatedText)
    {
        try
        {
            var payload = JsonSerializer.Deserialize<ClinicalAiPayload>(
                ExtractJson(generatedText),
                SerializerOptions);

            if (payload is not null && !string.IsNullOrWhiteSpace(payload.DiagnosticReport))
            {
                return payload;
            }
        }
        catch (JsonException ex)
        {
            _ragLogger.LogError(
                ex,
                "Clinical diagnosis JSON parsing failed. Persisting raw AI text.");
        }

        return new ClinicalAiPayload { DiagnosticReport = generatedText };
    }

    private static string ExtractJson(string text)
    {
        var trimmed = text.Trim();

        if (!trimmed.StartsWith("```", StringComparison.Ordinal))
        {
            return trimmed;
        }

        var firstBrace = trimmed.IndexOf('{', StringComparison.Ordinal);
        var lastBrace = trimmed.LastIndexOf('}');

        return firstBrace >= 0 && lastBrace > firstBrace
            ? trimmed[firstBrace..(lastBrace + 1)]
            : trimmed;
    }

    private static string BuildUserQuery(ClinicalDiagnosisRequest request)
    {
        var conditions = string.IsNullOrWhiteSpace(request.Conditions)
            ? "None reported"
            : request.Conditions;

        return $"Food preferences: {request.Preferences}\nMedical conditions: {conditions}";
    }

    private sealed class ClinicalAiPayload
    {
        public string DiagnosticReport { get; set; } = string.Empty;

        public List<MealSuggestion> MealSuggestions { get; set; } = new();
    }
}
