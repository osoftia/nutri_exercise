using Pgvector;

namespace NutriExercise.Core.Entities;

public class ResearchDocument
{
    public Guid Id { get; set; }

    public string Title { get; set; } = string.Empty;

    public string Content { get; set; } = string.Empty;

    public string Source { get; set; } = string.Empty;

    /// <summary>
    /// Muscle / body zone tag (e.g. "Chest", "Legs"). Mirrors the
    /// frontend ingest form's "Body Zone" field; persisted alongside
    /// <see cref="Source"/> for pgvector filtering.
    /// </summary>
    public string BodyZone { get; set; } = string.Empty;

    /// <summary>
    /// Owner of the document. Defaults to the seeded test user
    /// (<c>UserId = 1</c>) when no auth token is provided.
    /// </summary>
    public int UserId { get; set; } = 1;

    public Vector? Embedding { get; set; }
}
