using System.Net.Http.Json;
using System.Text.Json.Serialization;
using NutriExercise.Core.Interfaces;

namespace NutriExercise.Infrastructure.Services;

public class OllamaAiModelService : IAiModelService
{
    private const string Model = "llama3";

    private readonly HttpClient _httpClient;

    public OllamaAiModelService(IHttpClientFactory httpClientFactory)
    {
        ArgumentNullException.ThrowIfNull(httpClientFactory);

        _httpClient = httpClientFactory.CreateClient("Ollama");
    }

    public async Task<string> GenerateAsync(
        string systemPrompt,
        string userQuery,
        IReadOnlyList<string> contexts,
        double temperature,
        CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(contexts);

        var request = new OllamaGenerateRequest
        {
            Model = Model,
            Prompt = BuildPrompt(systemPrompt, userQuery, contexts),
            Stream = false,
            Options = new OllamaOptions { Temperature = temperature }
        };

        using var response = await _httpClient.PostAsJsonAsync(
            "api/generate",
            request,
            cancellationToken);

        response.EnsureSuccessStatusCode();

        var result = await response.Content
            .ReadFromJsonAsync<OllamaGenerateResponse>(cancellationToken);

        return result?.Response ?? string.Empty;
    }

    private static string BuildPrompt(
        string systemPrompt,
        string userQuery,
        IReadOnlyList<string> contexts)
    {
        var contextBlock = contexts.Count > 0
            ? string.Join(
                "\n",
                contexts.Select((context, index) => $"[{index + 1}] {context}"))
            : "No additional context available.";

        return $"{systemPrompt}\n\n" +
               $"Scientific context:\n{contextBlock}\n\n" +
               $"User query: {userQuery}";
    }

    private sealed class OllamaGenerateRequest
    {
        [JsonPropertyName("model")]
        public string Model { get; set; } = string.Empty;

        [JsonPropertyName("prompt")]
        public string Prompt { get; set; } = string.Empty;

        [JsonPropertyName("stream")]
        public bool Stream { get; set; }

        [JsonPropertyName("options")]
        public OllamaOptions? Options { get; set; }
    }

    private sealed class OllamaOptions
    {
        [JsonPropertyName("temperature")]
        public double Temperature { get; set; }
    }

    private sealed class OllamaGenerateResponse
    {
        [JsonPropertyName("response")]
        public string Response { get; set; } = string.Empty;
    }
}
