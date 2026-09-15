using EcoLoop.Api.DTOs;
using EcoLoop.Api.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace EcoLoop.Api.Controllers;

[ApiController]
[Route("api/business-profiles")]
public class BusinessProfilesController : ControllerBase
{
    private readonly IBusinessProfileService _service;

    public BusinessProfilesController(IBusinessProfileService service)
    {
        _service = service;
    }

    [HttpPost]
    public async Task<IActionResult> CreateProfile(
        [FromBody] CreateBusinessProfileRequest request)
    {
        if (!ModelState.IsValid)
        {
            return BadRequest(ModelState);
        }

        Guid? userId = null;
        if (Request.Headers.TryGetValue("X-User-Id", out var userIdHeader) &&
            Guid.TryParse(userIdHeader, out var parsedHeaderGuid))
        {
            userId = parsedHeaderGuid;
        }

        try
        {
            var profile = await _service.CreateAsync(request, userId);
            return CreatedAtAction(
                nameof(GetById),
                new { id = profile.Id },
                profile);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> GetById(Guid id)
    {
        var profile = await _service.GetByIdAsync(id);
        return profile == null
            ? NotFound(new { message = "Business profile not found." })
            : Ok(profile);
    }

    [HttpGet("user/{userId:guid}")]
    public async Task<IActionResult> GetByUserId(Guid userId)
    {
        var profile = await _service.GetByUserIdAsync(userId);
        return profile == null
            ? NotFound(new { message = "Business profile not found for this user." })
            : Ok(profile);
    }

    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var profiles = await _service.GetAllAsync();
        return Ok(profiles);
    }
}
