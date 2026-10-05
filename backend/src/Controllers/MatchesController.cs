using EcoLoop.Api.Services.Matching;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace EcoLoop.Api.Controllers;

// AI match suggestions for the signed-in account. The user - never the AI -
// decides to Connect or mark a match Not Interested (spec section 10).
[ApiController]
[Route("api/matches")]
[Authorize]
public class MatchesController(MatchingService matching) : ControllerBase
{
    [HttpGet]
    public async Task<IActionResult> Mine() => Ok(await matching.GetMineAsync(User.BusinessId()));

    // Latest AI check per active post ("why don't I have matches?").
    [HttpGet("activity")]
    public async Task<IActionResult> Activity() => Ok(await matching.GetMyActivityAsync(User.BusinessId()));

    [HttpPost("{id:guid}/connect")]
    public Task<IActionResult> Connect(Guid id) =>
        Run(async () => Ok(await matching.ConnectAsync(User.BusinessId(), id)));

    [HttpPost("{id:guid}/dismiss")]
    public Task<IActionResult> Dismiss(Guid id) =>
        Run(async () =>
        {
            await matching.DismissAsync(User.BusinessId(), id);
            return NoContent();
        });

    // "Find matches" for one of my posts (also useful for posts created before the AI existed).
    [HttpPost("listings/{listingId:guid}/run")]
    public Task<IActionResult> RunForListing(Guid listingId) =>
        Run(async () =>
        {
            var workflow = await matching.StartAsync(listingId, User.BusinessId());
            return Accepted(new { workflowId = workflow.Id, state = workflow.State });
        });

    [HttpGet("listings/{listingId:guid}/status")]
    public Task<IActionResult> Status(Guid listingId) =>
        Run(async () =>
        {
            var status = await matching.GetLatestStatusAsync(User.BusinessId(), listingId);
            return status == null ? NoContent() : Ok(status);
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
    }
}
