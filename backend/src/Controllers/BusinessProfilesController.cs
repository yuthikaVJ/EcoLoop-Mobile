using System.Security.Claims;
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

        var userId = GetRequestUserId();

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

    [HttpGet("my")]
    public async Task<IActionResult> GetMyProfiles([FromQuery] string? email)
    {
        var userId = GetRequestUserId();
        var effectiveEmail = !string.IsNullOrWhiteSpace(email)
            ? email
            : (Request.Headers.TryGetValue("X-User-Email", out var emailHeader) ? emailHeader.ToString() : null);

        var profiles = await _service.GetMyProfilesAsync(userId, effectiveEmail);
        return Ok(profiles);
    }

    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var profiles = await _service.GetAllAsync();
        return Ok(profiles);
    }

    [HttpPut("{id:guid}")]
    public async Task<IActionResult> UpdateProfile(
        Guid id,
        [FromBody] UpdateBusinessProfileRequest request)
    {
        if (!ModelState.IsValid)
        {
            return BadRequest(ModelState);
        }

        var userId = GetRequestUserId();

        try
        {
            var updated = await _service.UpdateAsync(id, request, userId);
            return Ok(updated);
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
        catch (UnauthorizedAccessException ex)
        {
            return StatusCode(StatusCodes.Status403Forbidden, new { message = ex.Message });
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPost("{id:guid}/upload-image")]
    [Consumes("multipart/form-data")]
    public async Task<IActionResult> UploadImage(
        Guid id,
        IFormFile? file,
        [FromForm] string? imageType,
        [FromQuery] string? queryImageType)
    {
        var type = !string.IsNullOrWhiteSpace(imageType) ? imageType : queryImageType;
        if (string.IsNullOrWhiteSpace(type))
        {
            return BadRequest(new { message = "imageType is required ('profile' or 'cover')." });
        }

        if (file == null || file.Length == 0)
        {
            return BadRequest(new { message = "An image file must be provided." });
        }

        var userId = GetRequestUserId();

        try
        {
            using var stream = file.OpenReadStream();
            var updated = await _service.UploadImageAsync(
                id,
                stream,
                file.FileName,
                file.ContentType,
                type,
                userId);

            return Ok(updated);
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
        catch (UnauthorizedAccessException ex)
        {
            return StatusCode(StatusCodes.Status403Forbidden, new { message = ex.Message });
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpDelete("{id:guid}/image")]
    public async Task<IActionResult> DeleteImage(
        Guid id,
        [FromQuery] string imageType)
    {
        if (string.IsNullOrWhiteSpace(imageType))
        {
            return BadRequest(new { message = "imageType query parameter is required ('profile' or 'cover')." });
        }

        var userId = GetRequestUserId();

        try
        {
            var updated = await _service.DeleteImageAsync(id, imageType, userId);
            return Ok(updated);
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
        catch (UnauthorizedAccessException ex)
        {
            return StatusCode(StatusCodes.Status403Forbidden, new { message = ex.Message });
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> DeleteProfile(Guid id)
    {
        var userId = GetRequestUserId();

        try
        {
            await _service.DeleteAsync(id, userId);
            return NoContent();
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
        catch (UnauthorizedAccessException ex)
        {
            return StatusCode(StatusCodes.Status403Forbidden, new { message = ex.Message });
        }
    }

    [HttpGet("{id:guid}/posts")]
    public async Task<IActionResult> GetProfilePosts(Guid id)
    {
        var posts = await _service.GetPostsByBusinessIdAsync(id);
        return Ok(posts);
    }

    private Guid? GetRequestUserId()
    {
        if (Request.Headers.TryGetValue("X-User-Id", out var userIdHeader) &&
            Guid.TryParse(userIdHeader, out var parsedHeaderGuid))
        {
            return parsedHeaderGuid;
        }

        var claimVal = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (claimVal != null && Guid.TryParse(claimVal, out var parsedClaimGuid))
        {
            return parsedClaimGuid;
        }

        return null;
    }
}
