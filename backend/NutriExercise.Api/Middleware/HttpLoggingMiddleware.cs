using System.Diagnostics;
using System.Text;
using Serilog;

namespace NutriExercise.Api.Middleware;

public class HttpLoggingMiddleware
{
    private const int MaxBodyLength = 4096;

    private static readonly string[] SensitiveHeaders = { "Authorization", "Cookie", "Set-Cookie" };

    private readonly RequestDelegate _next;
    private readonly Serilog.ILogger _logger;

    public HttpLoggingMiddleware(RequestDelegate next, Serilog.ILogger logger)
    {
        ArgumentNullException.ThrowIfNull(next);
        ArgumentNullException.ThrowIfNull(logger);

        _next = next;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        ArgumentNullException.ThrowIfNull(context);

        context.Request.EnableBuffering();
        var requestBody = await ReadAsync(context.Request.Body, context.RequestAborted);
        context.Request.Body.Position = 0;

        _logger.Information(
            "[HTTP-REQUEST] {Method} {Path}{Query} ClientIp={ClientIp} Headers={Headers} Body={Body}",
            context.Request.Method,
            context.Request.Path.Value ?? "/",
            context.Request.QueryString.Value ?? string.Empty,
            ResolveClientIp(context),
            FormatHeaders(context.Request.Headers),
            requestBody);

        var stopwatch = Stopwatch.StartNew();
        var originalBody = context.Response.Body;
        await using var responseBuffer = new MemoryStream();
        context.Response.Body = responseBuffer;

        try
        {
            await _next(context);
        }
        catch (Exception ex)
        {
            stopwatch.Stop();
            context.Response.Body = originalBody;
            _logger.Error(
                ex,
                "[HTTP-ERROR] {Method} {Path} ClientIp={ClientIp} ElapsedMs={ElapsedMs}: {ExceptionMessage}",
                context.Request.Method,
                context.Request.Path.Value ?? "/",
                ResolveClientIp(context),
                stopwatch.ElapsedMilliseconds,
                ex.Message);
            throw;
        }

        stopwatch.Stop();
        var responseBody = await ReadAsync(responseBuffer, context.RequestAborted);
        context.Response.Body = originalBody;
        await responseBuffer.CopyToAsync(originalBody, context.RequestAborted);

        _logger.Information(
            "[HTTP-RESPONSE] {Method} {Path} StatusCode={StatusCode} ElapsedMs={ElapsedMs} Headers={Headers} Body={Body}",
            context.Request.Method,
            context.Request.Path.Value ?? "/",
            context.Response.StatusCode,
            stopwatch.ElapsedMilliseconds,
            FormatHeaders(context.Response.Headers),
            responseBody);
    }

    private static string ResolveClientIp(HttpContext context) =>
        context.Connection.RemoteIpAddress?.ToString() ?? "unknown";

    private static async Task<string> ReadAsync(Stream stream, CancellationToken cancellationToken)
    {
        if (!stream.CanSeek)
        {
            return "(unreadable)";
        }

        stream.Position = 0;
        using var reader = new StreamReader(stream, Encoding.UTF8, leaveOpen: true);
        var content = await reader.ReadToEndAsync(cancellationToken);

        return Truncate(content);
    }

    private static string Truncate(string value)
    {
        if (string.IsNullOrEmpty(value))
        {
            return "(empty)";
        }

        return value.Length <= MaxBodyLength
            ? value
            : value[..MaxBodyLength] + "...(truncated)";
    }

    private static string FormatHeaders(IHeaderDictionary headers) =>
        string.Join(
            "; ",
            headers.Select(header =>
                $"{header.Key}: {(IsSensitive(header.Key) ? "[REDACTED]" : header.Value.ToString())}"));

    private static bool IsSensitive(string headerName) =>
        SensitiveHeaders.Contains(headerName, StringComparer.OrdinalIgnoreCase);
}
