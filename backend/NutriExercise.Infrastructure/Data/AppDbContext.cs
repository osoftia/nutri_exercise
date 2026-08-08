using Microsoft.EntityFrameworkCore;
using NutriExercise.Core.Entities;

namespace NutriExercise.Infrastructure.Data;

public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options)
        : base(options)
    {
    }

    public DbSet<User> Users => Set<User>();

    public DbSet<Routine> Routines => Set<Routine>();

    public DbSet<Diet> Diets => Set<Diet>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        modelBuilder.HasPostgresExtension("vector");
    }
}
