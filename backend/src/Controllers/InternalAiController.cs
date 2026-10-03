using System.Security.Cryptography;
using System.Text;
using EcoLoop.Api.DTOs;
using EcoLoop.Api.Services.Matching;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;

namespace EcoLoop.Api.Controllers;

// Allow-listed tools for the Python AI service. Each call is scoped to one running
// workflow and re-checked here, so the AI can't read posts outside that workflow.
[ApiController]
[Route("api/internal/ai/workflows/{workflowId:guid}")]
[ServiceFilter(typeof(AiServiceKeyFilter))]
public class InternalAiController(MatchingService matching) : ControllerBase
{
    [HttpGet("post")]
    public Task<IActionResult> Post(Guid workflowId) =>
        Run(async () => Ok(await matching.GetTriggerPostAsync(workflowId)));

    [HttpPost("candidates")]
    public Task<IActionResult> Candidates(Guid workflowId, [FromBody] AiCandidateSearchRequest request) =>
        Run(async () => Ok(await matching.SearchCandidatesAsync(workflowId, request.Categories, request.Limit)));

    [HttpPost("distance")]
    public Task<IActionResult> Distance(Guid workflowId, [FromBody] AiDistanceRequest request, CancellationToken cancellationToken) =>
        Run(async () => Ok(new { distanceKm = await matching.GetDistanceKmAsync(workflowId, request.CandidateId, cancellationToken) }));

    [HttpPost("state")]
    public Task<IActionResult> State(Guid workflowId, [FromBody] AiStateReport report) =>
        Run(async () =>
        {
            await matching.ReportStateAsync(workflowId, report.State, report.Note);
            return NoContent();
        });

    private async Task<IActionResult> Run(Func<Task<IActionResult>> action)
    {
        try
        {
            return await action();
        }
        catch (KeyNotFoundException ex) { return NotFound(new { message = ex.Message }); }
        catch (UnauthorizedAccessException ex) { return StatusCode(StatusCodes.Status403Forbidden, new { message = ex.Message }); }
        catch (InvalidOperationException ex) { return Conflict(new { message = ex.Message }); }
        catch (ArgumentException ex) { return BadRequest(new { message = ex.Message }); }
    }
}

// Shared-secret check for service-to-service calls (constant-time comparison).
public class AiServiceKeyFilter(IConfiguration configuration) : IAuthorizationFilter
{
    public void OnAuthorization(AuthorizationFilterContext context)
    {
        var expected = configuration["AiService:ApiKey"];
        if (string.IsNullOrWhiteSpace(expected))
        {
            context.Result = new ObjectResult(new { message = "AiService:ApiKey is not configured." }) { StatusCode = 503 };
            return;
        }
        var given = context.HttpContext.Request.Headers["X-AI-Service-Key"].ToString();
        if (!CryptographicOperations.FixedTimeEquals(Encoding.UTF8.GetBytes(given), Encoding.UTF8.GetBytes(expected)))
            context.Result = new UnauthorizedResult();
    }
}
