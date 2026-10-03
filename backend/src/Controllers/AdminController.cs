using System.Security.Claims;
using EcoLoop.Api.DTOs;
using EcoLoop.Api.Services.Interfaces;
using EcoLoop.Api.Services.Matching;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace EcoLoop.Api.Controllers;

// Used by the admin web. Admins are accounts with Businesses.IsAdmin = true,
// which AuthController turns into the "Admin" role claim.
[ApiController]
[Route("api/admin")]
[Authorize(Roles = "Admin")]
public class AdminController : ControllerBase
{
    private readonly IBusinessVerificationService _verifications;
    private readonly MatchingService _matching;

    public AdminController(IBusinessVerificationService verifications, MatchingService matching)
    {
        _verifications = verifications;
        _matching = matching;
    }

    // Audit view of AI matching runs (spec sections 11 and 15).
    [HttpGet("ai-workflows")]
    public async Task<IActionResult> AiWorkflows([FromQuery] string? state = "all") =>
        Ok(await _matching.GetWorkflowsAsync(state));

    [HttpGet("ai-workflows/{id:guid}")]
    public async Task<IActionResult> AiWorkflow(Guid id) =>
        await _matching.GetWorkflowAsync(id) is { } details ? Ok(details) : NotFound();

    [HttpGet("me")]
    public IActionResult Me() => Ok(new
    {
        id = User.BusinessId(),
        name = User.FindFirstValue(ClaimTypes.Name),
        email = User.FindFirstValue(ClaimTypes.Email),
    });

    [HttpGet("business-verifications/summary")]
    public async Task<IActionResult> Summary() => Ok(await _verifications.GetSummaryAsync());

    // status: Unverified (pending), Verified, Rejected or all.
    [HttpGet("business-verifications")]
    public async Task<IActionResult> List(
        [FromQuery] string? status = "Unverified",
        [FromQuery] string? search = null) =>
        Ok(await _verifications.GetRequestsAsync(status, search));

    [HttpPost("business-verifications/{id:guid}/approve")]
    public async Task<IActionResult> Approve(Guid id)
    {
        try
        {
            return Ok(await _verifications.ApproveAsync(id));
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
    }

    [HttpPost("business-verifications/{id:guid}/reject")]
    public async Task<IActionResult> Reject(Guid id, [FromBody] RejectBusinessRequest request)
    {
        if (!ModelState.IsValid) return BadRequest(ModelState);

        try
        {
            return Ok(await _verifications.RejectAsync(id, request.Reason));
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
    }
}
