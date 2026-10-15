using System.Net.Http.Json;
using System.Text.Json;
using System.Text.Json.Serialization;
using Microsoft.Extensions.Logging;
using NutriExercise.Core.Interfaces;

namespace NutriExercise.Infrastructure.Services;

#pragma warning disable CA1848 // Dynamic prefixed lifecycle logging requires runtime-formatted messages.
public class OllamaAiModelService : IAiModelService
{
    private const string Model = "llama3";

    private readonly HttpClient _httpClient;
    private readonly ILogger<OllamaAiModelService> _logger;

    public OllamaAiModelService(
        IHttpClientFactory httpClientFactory,
        ILogger<OllamaAiModelService> logger)
    {
        ArgumentNullException.ThrowIfNull(httpClientFactory);
        ArgumentNullException.ThrowIfNull(logger);

        _httpClient = httpClientFactory.CreateClient("Ollama");
        _logger = logger;
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

        using var response = await SendAsync(request, cancellationToken);

        response.EnsureSuccessStatusCode();

        var result = await response.Content
            .ReadFromJsonAsync<OllamaGenerateResponse>(cancellationToken);

        return result?.Response ?? string.Empty;
    }

    private async Task<HttpResponseMessage> SendAsync(
        OllamaGenerateRequest request,
        CancellationToken cancellationToken)
    {
        var endpoint = new Uri(_httpClient.BaseAddress ?? new Uri("http://localhost:11434/"), "api/generate");

        try
        {
            var response = await _httpClient.PostAsJsonAsync(endpoint, request, cancellationToken);

            if (!response.IsSuccessStatusCode)
            {
                var error = await response.Content.ReadAsStringAsync(cancellationToken);
                _logger.LogError(
                    "[OLLAMA-ERROR] Model {Model} returned {StatusCode} from {Endpoint}. Response: {ErrorResponse}",
                    Model,
                    (int)response.StatusCode,
                    endpoint,
                    error);
            }

            return response;
        }
        catch (Exception ex) when (ex is HttpRequestException or TaskCanceledException or JsonException)
        {
            _logger.LogError(
                ex,
                "[OLLAMA-ERROR] Failed to reach Ollama at {Endpoint} for model {Model}",
                endpoint,
                Model);
            throw;
        }
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
#pragma warning restore CA1848
