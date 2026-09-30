using System.Security.Claims;
using EcoLoop.Api.DTOs;
using EcoLoop.Api.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace EcoLoop.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class BusinessController : ControllerBase
{
    private readonly IBusinessService _businessService;

    public BusinessController(IBusinessService businessService)
    {
        _businessService = businessService;
    }

    [HttpGet("me")]
    public async Task<ActionResult<BusinessProfileDto>> GetMyProfile()
    {
        var businessIdClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (string.IsNullOrEmpty(businessIdClaim) || !Guid.TryParse(businessIdClaim, out var businessId))
        {
            return Unauthorized();
        }

        var profile = await _businessService.GetProfileAsync(businessId);
        if (profile == null)
        {
            return NotFound("Business profile not found.");
        }

        return Ok(profile);
    }

    [HttpPut("me")]
    public async Task<ActionResult<BusinessProfileDto>> UpdateMyProfile([FromBody] UpdateBusinessProfileRequest request)
    {
        var businessIdClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (string.IsNullOrEmpty(businessIdClaim) || !Guid.TryParse(businessIdClaim, out var businessId))
        {
            return Unauthorized();
        }

        var updatedProfile = await _businessService.UpdateProfileAsync(businessId, request);
        if (updatedProfile == null)
        {
            return NotFound("Business profile not found.");
        }

        return Ok(updatedProfile);
    }
}
