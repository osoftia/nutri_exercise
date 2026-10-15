using Microsoft.EntityFrameworkCore;
using NutriExercise.Api.Middleware;
using NutriExercise.Core.Configuration;
using NutriExercise.Core.Interfaces;
using NutriExercise.Infrastructure.Data;
using NutriExercise.Infrastructure.Logging;
using NutriExercise.Infrastructure.Services;
using Pgvector.EntityFrameworkCore;
using Serilog;
using Serilog.Events;
using Serilog.Formatting.Json;

var builder = WebApplication.CreateBuilder(args);

const string PlainTextTemplate =
    "[{Timestamp:yyyy-MM-dd HH:mm:ss.fff} {Level:u3}] {Message:lj}{NewLine}{Exception}";

Log.Logger = new LoggerConfiguration()
    .MinimumLevel.Information()
    .MinimumLevel.Override("Microsoft.AspNetCore", LogEventLevel.Warning)
    .Enrich.FromLogContext()
    .WriteTo.Console(outputTemplate: PlainTextTemplate)
    .WriteTo.File(
        path: "Logs/nutriexercise-.log",
        rollingInterval: RollingInterval.Day,
        retainedFileCountLimit: 30,
        shared: true,
        outputTemplate: PlainTextTemplate)
    .WriteTo.File(
        new JsonFormatter(renderMessage: true),
        path: "Logs/nutriexercise-.json",
        rollingInterval: RollingInterval.Day,
        retainedFileCountLimit: 30,
        shared: true)
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
    builder.Services.AddSingleton<Serilog.ILogger>(Log.Logger);
    builder.Services.AddDbContext<AppDbContext>(options =>
        options.UseNpgsql(
            builder.Configuration.GetConnectionString("DefaultConnection"),
            o => o.UseVector()));

    builder.Services.AddHttpClient("Ollama", client =>
    {
        client.BaseAddress = new Uri("http://localhost:11434/");
        client.Timeout = TimeSpan.FromMinutes(5);
    });
    builder.Services.AddScoped<IRagLogger, RagLogger>();
    builder.Services.AddScoped<IAiService, OllamaAiService>();
    builder.Services.AddScoped<IRoutineRepository, RoutineRepository>();
    builder.Services.AddScoped<IResearchDocumentRepository, ResearchDocumentRepository>();
    builder.Services.AddScoped<IDailyLogRepository, DailyLogRepository>();
    builder.Services.AddScoped<IUserRepository, UserRepository>();
    builder.Services.AddScoped<IVectorSearchService, VectorSearchService>();
    builder.Services.AddScoped<IHealthDataService, HealthDataService>();
    builder.Services.AddScoped<IAiModelService, OllamaAiModelService>();
    builder.Services.AddScoped<IClinicalDiagnosisService, ClinicalDiagnosisService>();
    builder.Services.AddScoped<IClinicalGuardrailService, ClinicalGuardrailService>();
    builder.Services.AddScoped<IClinicalMenuRepository, ClinicalMenuRepository>();
    builder.Services.AddScoped<ClinicalMenuStore>();
    builder.Services.AddScoped<IClinicalMenuService, ClinicalMenuService>();
    builder.Services.AddScoped<BaselineKnowledgeSeeder>();
    builder.Services.AddScoped<DbInitializer>();

    builder.Services.Configure<LogReaderSettings>(
        builder.Configuration.GetSection(LogReaderSettings.SectionName));

    builder.Services.AddSingleton<ILogReaderService>(serviceProvider =>
    {
        var settings = serviceProvider
            .GetRequiredService<Microsoft.Extensions.Options.IOptions<LogReaderSettings>>()
            .Value;
        var logger = serviceProvider.GetRequiredService<ILogger<FileLogReaderService>>();
        var directory = Path.IsPathRooted(settings.Directory)
            ? settings.Directory
            : Path.Combine(builder.Environment.ContentRootPath, settings.Directory);

        return new FileLogReaderService(
            directory,
            logger,
            settings.FileSearchPattern,
            settings.MaxPageSize);
    });

    builder.Services.Configure<RagSettings>(
        builder.Configuration.GetSection(RagSettings.SectionName));

    var useMockRag = builder.Configuration.GetValue<bool>(
        $"{RagSettings.SectionName}:UseMockMode");

    if (useMockRag)
    {
        builder.Services.AddScoped<IRagOrchestrator, MockRagOrchestrator>();
    }
    else
    {
        builder.Services.AddScoped<IRagOrchestrator, RealRagOrchestrator>();
    }

    var app = builder.Build();

    using (var scope = app.Services.CreateScope())
    {
        var initializer = scope.ServiceProvider.GetRequiredService<DbInitializer>();
        await initializer.InitializeAsync();
    }

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

    app.UseMiddleware<HttpLoggingMiddleware>();

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