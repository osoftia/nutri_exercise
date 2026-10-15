using System.Net;
using System.Text;
using FluentAssertions;
using Microsoft.AspNetCore.Http;
using NutriExercise.Api.Middleware;
using NutriExercise.Specs.Support;
using Reqnroll;
using Serilog;
using Serilog.Events;

namespace NutriExercise.Specs.Steps;

[Binding]
public class HttpLoggingSteps
{
    private readonly InMemoryLogSink _sink = new();
    private DefaultHttpContext _context = new();
    private Exception? _thrown;

    [Given(@"a mobile client at IP ""(.*)"" sends a ""(.*)"" request to ""(.*)""")]
    public void GivenAMobileClientSendsARequest(string ip, string method, string path)
    {
        _context = new DefaultHttpContext();
        _context.Connection.RemoteIpAddress = IPAddress.Parse(ip);
        _context.Request.Method = method;
        _context.Request.Path = path;
        _context.Request.Body = new MemoryStream();
        _context.Response.Body = new MemoryStream();
    }

    [Given(@"the request carries the header ""(.*)"" with value ""(.*)""")]
    public void GivenTheRequestCarriesHeader(string name, string value)
    {
        _context.Request.Headers[name] = value;
    }

    [Given(@"the request body is '(.*)'")]
    public void GivenTheRequestBodyIs(string body)
    {
        _context.Request.Body = new MemoryStream(Encoding.UTF8.GetBytes(body));
    }

    [When(@"the HTTP logging middleware processes the request")]
    public Task WhenTheMiddlewareProcessesTheRequest() =>
        RunMiddlewareAsync(toThrow: null);

    [When(@"the downstream pipeline throws a ""(.*)"" mentioning ""(.*)""")]
    public Task WhenTheDownstreamThrows(string exceptionType, string message) =>
        RunMiddlewareAsync(CreateException(exceptionType, message));

    [Then(@"the log should contain a ""(.*)"" entry with the remote IP ""(.*)""")]
    public void ThenTheLogShouldContainRequestEntry(string tag, string ip)
    {
        Find(tag).RenderMessage().Should().Contain(ip);
    }

    [Then(@"the log should contain the header ""(.*)""")]
    public void ThenTheLogShouldContainHeader(string header)
    {
        _sink.Events.Select(entry => entry.RenderMessage())
            .Should().Contain(message => message.Contains(header, StringComparison.Ordinal));
    }

    [Then(@"the log should contain the request body ""(.*)""")]
    public void ThenTheLogShouldContainBody(string body)
    {
        _sink.Events.Select(entry => entry.RenderMessage())
            .Should().Contain(message => message.Contains(body, StringComparison.Ordinal));
    }

    [Then(@"the log should contain a ""(.*)"" entry with status code (.*)")]
    public void ThenTheLogShouldContainResponseEntry(string tag, int status)
    {
        Find(tag).RenderMessage().Should().Contain($"StatusCode={status}");
    }

    [Then(@"the HTTP logging middleware should rethrow the exception")]
    public void ThenTheMiddlewareShouldRethrow()
    {
        _thrown.Should().BeOfType<HttpRequestException>();
    }

    [Then(@"the log should contain an ""(.*)"" entry with the stack trace")]
    public void ThenTheLogShouldContainErrorWithStack(string tag)
    {
        var entry = Find(tag);
        entry.Exception.Should().NotBeNull();
        entry.Exception!.ToString().Should().Contain("at ");
    }

    private async Task RunMiddlewareAsync(Exception? toThrow)
    {
        using var logger = new LoggerConfiguration()
            .MinimumLevel.Verbose()
            .WriteTo.Sink(_sink)
            .CreateLogger();

        RequestDelegate next = _ => toThrow is null
            ? Task.CompletedTask
            : Task.FromException(toThrow);

        var middleware = new HttpLoggingMiddleware(next, logger);

        try
        {
            await middleware.InvokeAsync(_context);
        }
        catch (Exception ex)
        {
            _thrown = ex;
        }
    }

    private LogEvent Find(string tag)
    {
        var match = _sink.Events.FirstOrDefault(
            entry => entry.RenderMessage().Contains(tag, StringComparison.Ordinal));
        match.Should().NotBeNull($"the log should contain an entry tagged {tag}");

        return match!;
    }

    private static Exception CreateException(string type, string message) =>
        type == nameof(HttpRequestException)
            ? new HttpRequestException(message)
            : new InvalidOperationException(message);
}
