using System.Net.Http.Json;
using System.Text.Json.Serialization;
using NutriExercise.Core.Interfaces;

namespace NutriExercise.Infrastructure.Services;

public class OllamaAiService : IAiService
{
    private readonly HttpClient _httpClient;

    public OllamaAiService(IHttpClientFactory httpClientFactory)
    {
        _httpClient = httpClientFactory.CreateClient("Ollama");
    }

    public async Task<string> GenerateRoutineAsync(string userPreferences, CancellationToken cancellationToken = default)
    {
        var request = new OllamaGenerateRequest
        {
            Model = "llama3",
            Prompt = BuildPrompt(userPreferences),
            Format = "json",
            Stream = false
        };

        using var response = await _httpClient.PostAsJsonAsync("api/generate", request, cancellationToken);

        response.EnsureSuccessStatusCode();

        var result = await response.Content.ReadFromJsonAsync<OllamaGenerateResponse>(cancellationToken);

        return result?.Response ?? string.Empty;
    }

    public async Task<string> GenerateJsonAsync(string userInput, CancellationToken cancellationToken = default)
    {
        var request = new OllamaGenerateRequest
        {
            Model = "llama3",
            Prompt = BuildLogExtractionPrompt(userInput),
            Format = "json",
            Stream = false
        };

        using var response = await _httpClient.PostAsJsonAsync("api/generate", request, cancellationToken);

        response.EnsureSuccessStatusCode();

        var result = await response.Content.ReadFromJsonAsync<OllamaGenerateResponse>(cancellationToken);

        return result?.Response ?? string.Empty;
    }

    public async Task<float[]> GenerateEmbeddingAsync(string text, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(text))
        {
            return Array.Empty<float>();
        }

        var request = new OllamaEmbeddingRequest
        {
            Model = "nomic-embed-text",
            Prompt = text
        };

        using var response = await _httpClient.PostAsJsonAsync("api/embeddings", request, cancellationToken);

        response.EnsureSuccessStatusCode();

        var result = await response.Content.ReadFromJsonAsync<OllamaEmbeddingResponse>(cancellationToken);

        return result?.Embedding ?? Array.Empty<float>();
    }

    private static string BuildPrompt(string userPreferences) =>
        $"You are a professional fitness coach. Based on the following user preferences, " +
        $"create a detailed weekly workout routine with exercises, sets, and reps. " +
        $"Keep it clear and structured. Preferences: {userPreferences}";

    private static string BuildLogExtractionPrompt(string userInput)
    {
        return $@"Eres un asistente de nutrición y entrenamiento. A partir del siguiente registro libre del usuario, extrae la información en un objeto JSON estricto y sin texto adicional antes o después:

Texto del usuario: {userInput}

REGLA ESTRICTA: Responde únicamente con un objeto JSON válido con esta estructura exacta:
{{
  ""calories"": 0,
  ""protein"": 0.0,
  ""carbs"": 0.0,
  ""fat"": 0.0,
  ""muscles"": [""Chest"", ""Back""]
}}

Usa nombres de músculos en inglés estandarizados (Chest, Back, Shoulders, Biceps, Triceps, Legs, Core, Arms). Estimaciones numéricas si el usuario no las da.";
    }

    private sealed class OllamaGenerateRequest
    {
        [JsonPropertyName("model")]
        public string Model { get; set; } = string.Empty;

        [JsonPropertyName("prompt")]
        public string Prompt { get; set; } = string.Empty;

        [JsonPropertyName("format")]
        public string Format { get; set; } = string.Empty;

        [JsonPropertyName("stream")]
        public bool Stream { get; set; }
    }

    private sealed class OllamaGenerateResponse
    {
        [JsonPropertyName("response")]
        public string Response { get; set; } = string.Empty;
    }

    private sealed class OllamaEmbeddingRequest
    {
        [JsonPropertyName("model")]
        public string Model { get; set; } = string.Empty;

        [JsonPropertyName("prompt")]
        public string Prompt { get; set; } = string.Empty;
    }

    private sealed class OllamaEmbeddingResponse
    {
        [JsonPropertyName("embedding")]
        public float[] Embedding { get; set; } = Array.Empty<float>();
    }
}
