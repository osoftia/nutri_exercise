using Microsoft.EntityFrameworkCore;
using NutriExercise.Core.Entities;

namespace NutriExercise.Infrastructure.Data;

public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options)
        : base(options)
    {
    }

    public virtual DbSet<User> Users => Set<User>();

    public virtual DbSet<Routine> Routines => Set<Routine>();

    public virtual DbSet<Diet> Diets => Set<Diet>();

    public virtual DbSet<ResearchDocument> ResearchDocuments => Set<ResearchDocument>();

    public virtual DbSet<AiInteraction> AiInteractions => Set<AiInteraction>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        modelBuilder.HasPostgresExtension("vector");

        // Code-first seed for the default RAG test user. The runtime
        // DbInitializer re-asserts the same row idempotently on startup.
        modelBuilder.Entity<User>().HasData(new User
        {
            Id = 1,
            Name = "Test User",
            Email = "test@nutriexercise.local",
        });

        modelBuilder.Entity<ResearchDocument>(b =>
        {
            b.Property(d => d.BodyZone).HasDefaultValue(string.Empty);
            b.Property(d => d.UserId).HasDefaultValue(1);
        });

        modelBuilder.Entity<AiInteraction>(b =>
        {
            b.Property(i => i.UserId).HasDefaultValue(1);
        });
    }
}
