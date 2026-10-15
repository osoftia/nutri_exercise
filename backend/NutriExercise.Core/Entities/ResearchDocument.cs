using Pgvector;

namespace NutriExercise.Core.Entities;

public class ResearchDocument
{
    public Guid Id { get; set; }

    public string Title { get; set; } = string.Empty;

    public string Content { get; set; } = string.Empty;

    public string Source { get; set; } = string.Empty;

    public string BodyZone { get; set; } = string.Empty;

    public int UserId { get; set; }

    public Vector? Embedding { get; set; }
}
