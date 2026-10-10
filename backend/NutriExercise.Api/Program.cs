using Microsoft.EntityFrameworkCore;
using NutriExercise.Core.Interfaces;
using NutriExercise.Infrastructure.Data;
using NutriExercise.Infrastructure.Services;
using Pgvector.EntityFrameworkCore;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowFrontendClients", policy =>
    {
        policy.WithOrigins(
            "http://localhost:4200",
            "http://localhost:5000",
            "http://127.0.0.1:5000",
            "http://10.0.2.2:5000",
            "http://localhost:5039",
            "http://127.0.0.1:5039",
            "http://10.0.2.2:5039")
            .AllowAnyMethod()
            .AllowAnyHeader();
    });
});
builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseNpgsql(
        builder.Configuration.GetConnectionString("DefaultConnection"),
        o => o.UseVector()));

builder.Services.AddHttpClient("Ollama", client =>
{
    client.BaseAddress = new Uri("http://localhost:11434/");
    client.Timeout = TimeSpan.FromMinutes(5);
});
builder.Services.AddScoped<IAiService, OllamaAiService>();
builder.Services.AddScoped<IRoutineRepository, RoutineRepository>();
builder.Services.AddScoped<IResearchDocumentRepository, ResearchDocumentRepository>();

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();

app.UseCors("AllowFrontendClients");

app.MapControllers();

// EF Core startup seeding: ensures Users.Id = 1 ("Test User") exists so
// RAG ingest/query can default to UserId = 1 without login. Runs on every
// boot (local Mac server included); failures are logged with [RAG-ERROR]:
// and do not crash the host so Swagger/health stay reachable.
using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    var seederLogger = scope.ServiceProvider.GetRequiredService<ILoggerFactory>().CreateLogger("RagSeeding");
    try
    {
        await NutriExercise.Infrastructure.Data.DbInitializer.SeedAsync(db, seederLogger);
    }
    catch (Exception ex)
    {
        seederLogger.LogError(ex, "[RAG-ERROR]: startup database seeding failed — API continues without seeded test user.");
    }
}

app.Run();
