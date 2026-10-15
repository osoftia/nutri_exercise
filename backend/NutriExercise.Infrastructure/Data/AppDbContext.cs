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

    public virtual DbSet<DailyLogRecord> DailyLogRecords => Set<DailyLogRecord>();

    public virtual DbSet<AiTrainingTrace> AiTrainingTraces => Set<AiTrainingTrace>();

    public virtual DbSet<ErrorLog> ErrorLogs => Set<ErrorLog>();

    public virtual DbSet<ClinicalDiagnosisReport> ClinicalDiagnosisReports => Set<ClinicalDiagnosisReport>();

    public virtual DbSet<DailySymptomLog> DailySymptomLogs => Set<DailySymptomLog>();

    public virtual DbSet<ClinicalMenuPlan> ClinicalMenuPlans => Set<ClinicalMenuPlan>();

    public virtual DbSet<HealthMetric> HealthMetrics => Set<HealthMetric>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        ArgumentNullException.ThrowIfNull(modelBuilder);

        base.OnModelCreating(modelBuilder);

        modelBuilder.Entity<HealthMetric>(metric =>
        {
            metric.Property(m => m.MetricType).HasMaxLength(64).IsRequired();
            metric.Property(m => m.Unit).HasMaxLength(32).IsRequired();
            metric.HasIndex(m => new { m.UserId, m.MetricType, m.Timestamp }).IsUnique();
        });

        if (Database.IsNpgsql())
        {
            modelBuilder.HasPostgresExtension("vector");
            return;
        }

        // Non-relational/test providers cannot map the pgvector type.
        modelBuilder.Entity<ResearchDocument>().Ignore(document => document.Embedding);
    }
}
