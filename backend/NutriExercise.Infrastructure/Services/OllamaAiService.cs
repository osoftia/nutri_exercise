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
            Stream = false
        };

        using var response = await _httpClient.PostAsJsonAsync("api/generate", request, cancellationToken);

        response.EnsureSuccessStatusCode();

        var result = await response.Content.ReadFromJsonAsync<OllamaGenerateResponse>(cancellationToken);

        return result?.Response ?? string.Empty;
    }

    private static string BuildPrompt(string userPreferences) =>
        $"You are a professional fitness coach. Based on the following user preferences, " +
        $"create a detailed weekly workout routine with exercises, sets, and reps. " +
        $"Keep it clear and structured. Preferences: {userPreferences}";

    private sealed class OllamaGenerateRequest
    {
        [JsonPropertyName("model")]
        public string Model { get; set; } = string.Empty;

        [JsonPropertyName("prompt")]
        public string Prompt { get; set; } = string.Empty;

        [JsonPropertyName("stream")]
        public bool Stream { get; set; }
    }

    private sealed class OllamaGenerateResponse
    {
        [JsonPropertyName("response")]
        public string Response { get; set; } = string.Empty;
    }
}
