using Microsoft.EntityFrameworkCore;
using NutriExercise.Api.Middleware;
using NutriExercise.Core.Interfaces;
using NutriExercise.Infrastructure.Data;
using NutriExercise.Infrastructure.Logging;
using NutriExercise.Infrastructure.Services;
using Pgvector.EntityFrameworkCore;
using Serilog;
using Serilog.Formatting.Json;

var builder = WebApplication.CreateBuilder(args);

var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");
var dbOptions = new DbContextOptionsBuilder<AppDbContext>()
    .UseNpgsql(connectionString, o => o.UseVector())
    .Options;

Log.Logger = new LoggerConfiguration()
    .MinimumLevel.Information()
    .WriteTo.Console()
    .WriteTo.File(new JsonFormatter(), "Logs/combined.log")
    .WriteTo.Sink(new ErrorLogSink(dbOptions))
    .CreateLogger();

try
{
    Log.Information("Starting up NutriExercise API...");

    builder.Host.UseSerilog();

    builder.Services.AddControllers();
    builder.Services.AddEndpointsApiExplorer();
    builder.Services.AddSwaggerGen();

    builder.Services.AddCors(options =>
    {
        options.AddPolicy("AllowAngularApp", policy =>
        {
            policy.WithOrigins(
                "http://localhost:4200",
                "http://127.0.0.1:4200",
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

    builder.Services.AddHealthChecks();
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
    builder.Services.AddScoped<IDailyLogRepository, DailyLogRepository>();
    builder.Services.AddScoped<IVectorSearchService, VectorSearchService>();
    builder.Services.AddScoped<IAiModelService, OllamaAiModelService>();

    var app = builder.Build();

    if (app.Environment.IsDevelopment())
    {
        app.UseSwagger();
        app.UseSwaggerUI();
    }

    if (!app.Environment.IsDevelopment())
    {
        app.UseHttpsRedirection();
    }

    app.UseMiddleware<GlobalExceptionMiddleware>();

    app.UseCors("AllowAngularApp");

    app.UseSerilogRequestLogging();

    app.MapControllers();

    app.MapHealthChecks("/health");

    app.Run();
}
catch (Exception ex)
{
    Log.Fatal(ex, "Application start-up failed");
    throw;
}
finally
{
    Log.CloseAndFlush();
}