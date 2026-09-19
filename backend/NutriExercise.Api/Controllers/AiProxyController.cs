using Microsoft.AspNetCore.Mvc;
using NutriExercise.Api.DTOs;
using NutriExercise.Core.Entities;
using NutriExercise.Core.Interfaces;
using NutriExercise.Infrastructure.Data;

namespace NutriExercise.Api.Controllers;

/// <summary>
/// RAG-backed conversational proxy. Embeds the user message, retrieves the
/// closest research documents with pgvector and forwards the augmented prompt
/// to the local LLM. Every exchange is persisted as an <see cref="AiInteraction"/>.
/// </summary>
[ApiController]
[Route("api/[controller]")]
public class AiProxyController : ControllerBase
{
    private readonly IAiService _aiService;
    private readonly IResearchDocumentRepository _documentRepository;
    private readonly AppDbContext _dbContext;

    public AiProxyController(
        IAiService aiService,
        IResearchDocumentRepository documentRepository,
        AppDbContext dbContext)
    {
        _aiService = aiService;
        _documentRepository = documentRepository;
        _dbContext = dbContext;
    }

    [HttpPost("chat")]
    public async Task<IActionResult> Chat([FromBody] ChatRequest request, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(request.Message))
        {
            return BadRequest("Message is required.");
        }

        var contextText = await RetrieveContextAsync(request.Message, cancellationToken);

        string reply;
        try
        {
            reply = await _aiService.GenerateChatAsync(
                BuildChatPrompt(request, contextText),
                cancellationToken);
        }
        catch (Exception ex) when (ex is HttpRequestException or TaskCanceledException)
        {
            return StatusCode(
                StatusCodes.Status502BadGateway,
                "The assistant is unavailable right now.");
        }

        if (string.IsNullOrWhiteSpace(reply))
        {
            return StatusCode(
                StatusCodes.Status502BadGateway,
                "The assistant returned an empty reply.");
        }

        var interaction = PersistInteraction(request.Message, reply, contextText);
        await _dbContext.SaveChangesAsync(cancellationToken);

        return Ok(new ChatResponseDto(interaction.Id, reply, interaction.ModelUsed, interaction.CreatedAt));
    }

    /// <summary>
    /// Best-effort pgvector retrieval: a retrieval failure degrades to an
    /// ungrounded reply instead of failing the whole exchange.
    /// </summary>
    private async Task<string> RetrieveContextAsync(string message, CancellationToken cancellationToken)
    {
        try
        {
            var queryVector = await _aiService.GenerateEmbeddingAsync(message, cancellationToken);
            if (queryVector.Length == 0)
            {
                return string.Empty;
            }

            var documents = await _documentRepository.SearchSimilarDocumentsAsync(
                queryVector,
                2,
                cancellationToken);

            return string.Join("\n", documents.Select(document => document.Content));
        }
        catch (Exception ex) when (ex is HttpRequestException or TaskCanceledException)
        {
            return string.Empty;
        }
    }

    private AiInteraction PersistInteraction(string prompt, string reply, string contextText)
    {
        var interaction = new AiInteraction
        {
            Id = Guid.NewGuid(),
            UserPrompt = prompt,
            GeneratedRoutine = reply,
            ModelUsed = string.IsNullOrWhiteSpace(contextText) ? "llama3" : "llama3-rag",
            UsedContext = contextText,
            CreatedAt = DateTime.UtcNow
        };

        _dbContext.AiInteractions.Add(interaction);
        return interaction;
    }

    private static string BuildChatPrompt(ChatRequest request, string contextText)
    {
        var grounding = string.IsNullOrWhiteSpace(contextText)
            ? string.Empty
            : $"Utiliza este conocimiento científico como referencia:\n{contextText}\n\n";

        var history = request.History is { Count: > 0 }
            ? string.Join("\n", request.History.Select(turn => $"{turn.Role}: {turn.Content}")) + "\n"
            : string.Empty;

        return $"{grounding}Conversación previa:\n{history}Usuario: {request.Message}\nAsistente:";
    }
}
