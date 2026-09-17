using EcoLoop.Api.Data;
using EcoLoop.Api.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;

namespace EcoLoop.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class NotificationsController : ControllerBase
{
    private readonly EcoLoopDbContext _db;

    public NotificationsController(EcoLoopDbContext db)
    {
        _db = db;
    }

    [HttpPost("register-device")]
    public async Task<IActionResult> RegisterDeviceToken([FromBody] RegisterDeviceRequest request)
    {
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(userIdClaim) || !Guid.TryParse(userIdClaim, out var userId))
        {
            return Unauthorized();
        }

        if (string.IsNullOrEmpty(request.Token))
        {
            return BadRequest("Token is required");
        }

        // Check if token already exists for this user
        var existing = await _db.DeviceTokens.FirstOrDefaultAsync(d => d.BusinessId == userId && d.Token == request.Token);
        if (existing == null)
        {
            _db.DeviceTokens.Add(new DeviceToken
            {
                BusinessId = userId,
                Token = request.Token,
                CreatedAt = DateTime.UtcNow
            });
            await _db.SaveChangesAsync();
        }

        return Ok(new { message = "Token registered successfully" });
    }
}

public class RegisterDeviceRequest
{
    public string Token { get; set; } = string.Empty;
}
