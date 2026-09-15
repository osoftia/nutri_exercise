using System.Diagnostics;
using Microsoft.AspNetCore.Mvc;
using NutriExercise.Core.DTOs;

namespace NutriExercise.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class RagController : ControllerBase
{
    [HttpPost("query")]
    public IActionResult Query([FromBody] RagRequest request)
    {
        ArgumentNullException.ThrowIfNull(request);

        var stopwatch = Stopwatch.StartNew();

        var retrievedContexts = new List<string>
        {
            "ACSM: at least 10 weekly sets per muscle group for hypertrophy.",
            "NIH: 2 to 3 minutes of rest between sets maximizes myofibrillar growth."
        };

        var pgVectorScores = new List<double> { 0.92, 0.87 };

        var generatedText = "Mocked RAG response: build volume progressively and keep protein high.";

        stopwatch.Stop();

        var response = new RagResponse(
            generatedText,
            retrievedContexts,
            new TelemetryData(stopwatch.ElapsedMilliseconds, pgVectorScores));

        return Ok(response);
    }
}
