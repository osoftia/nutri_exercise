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
    }
}
