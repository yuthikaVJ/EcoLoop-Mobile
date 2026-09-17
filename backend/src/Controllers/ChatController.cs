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
public class ChatController : ControllerBase
{
    private readonly EcoLoopDbContext _db;

    public ChatController(EcoLoopDbContext db)
    {
        _db = db;
    }

    [HttpGet("history/{listingId}")]
    public async Task<IActionResult> GetChatHistory(Guid listingId)
    {
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(userIdClaim) || !Guid.TryParse(userIdClaim, out var userId))
        {
            return Unauthorized();
        }

        // Fetch messages for this listing where the current user is either sender or receiver
        var messages = await _db.ChatMessages
            .Where(m => m.ListingId == listingId && (m.SenderId == userId || m.ReceiverId == userId))
            .OrderBy(m => m.CreatedAt)
            .Select(m => new
            {
                m.Id,
                m.ListingId,
                m.SenderId,
                m.ReceiverId,
                m.Content,
                m.CreatedAt,
                IsMe = m.SenderId == userId
            })
            .ToListAsync();

        return Ok(messages);
    }
}
