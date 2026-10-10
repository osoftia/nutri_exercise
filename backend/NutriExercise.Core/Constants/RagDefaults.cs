namespace NutriExercise.Core.Constants;

/// <summary>
/// Shared defaults for the RAG feature. Keeps the seeded test-user
/// identity in one place so API, Infrastructure and tests agree.
/// </summary>
public static class RagDefaults
{
    /// <summary>Id of the seeded test user used when no auth token is present.</summary>
    public const int DefaultUserId = 1;

    public const string DefaultUserName = "Test User";

    public const string DefaultUserEmail = "test@nutriexercise.local";

    /// <summary>Resolves an optional incoming user id to the effective owner.</summary>
    public static int ResolveUserId(int? candidate) => candidate is > 0 ? candidate.Value : DefaultUserId;
}
