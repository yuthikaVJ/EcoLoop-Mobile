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

    // Messages about a listing. With ?with={businessId} only the conversation between the
    // current user and that business is returned (a seller can have several buyers).
    [HttpGet("history/{listingId}")]
    public async Task<IActionResult> GetChatHistory(Guid listingId, [FromQuery(Name = "with")] Guid? withBusinessId)
    {
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(userIdClaim) || !Guid.TryParse(userIdClaim, out var userId))
        {
            return Unauthorized();
        }

        // Fetch messages for this listing where the current user is either sender or receiver
        var query = _db.ChatMessages
            .Where(m => m.ListingId == listingId && (m.SenderId == userId || m.ReceiverId == userId));
        if (withBusinessId is { } other)
            query = query.Where(m => m.SenderId == other || m.ReceiverId == other);

        var messages = await query
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

    // One row per conversation (listing + other business), newest first, so both the
    // buyer and the seller can find and reopen their chats.
    [HttpGet("inbox")]
    public async Task<IActionResult> GetInbox()
    {
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(userIdClaim) || !Guid.TryParse(userIdClaim, out var userId))
        {
            return Unauthorized();
        }

        var messages = await _db.ChatMessages
            .AsNoTracking()
            .Where(m => m.SenderId == userId || m.ReceiverId == userId)
            .Select(m => new
            {
                m.ListingId,
                OtherId = m.SenderId == userId ? m.ReceiverId : m.SenderId,
                m.Content,
                m.CreatedAt,
                IsMe = m.SenderId == userId
            })
            .ToListAsync();

        var latest = messages
            .GroupBy(m => new { m.ListingId, m.OtherId })
            .Select(g => g.OrderByDescending(m => m.CreatedAt).First())
            .OrderByDescending(m => m.CreatedAt)
            .ToList();

        var listingIds = latest.Select(m => m.ListingId).Distinct().ToList();
        var otherIds = latest.Select(m => m.OtherId).Distinct().ToList();
        var listings = await _db.MaterialListings.AsNoTracking()
            .Where(l => listingIds.Contains(l.Id))
            .Include(l => l.Business)
            .ToDictionaryAsync(l => l.Id);
        var others = await _db.Businesses.AsNoTracking()
            .Where(b => otherIds.Contains(b.Id))
            .ToDictionaryAsync(b => b.Id);

        var conversations = latest
            .Where(m => listings.ContainsKey(m.ListingId))
            .Select(m =>
            {
                var listing = listings[m.ListingId];
                return new
                {
                    m.ListingId,
                    ListingTitle = listing.Title,
                    ListingCategory = listing.Category,
                    ListingPrice = listing.Price,
                    ListingPriceUnit = listing.PriceUnit,
                    ListingQuantity = listing.Quantity,
                    ListingUnit = listing.Unit,
                    ListingLocation = listing.Location,
                    ListingType = (int)listing.Type,
                    ListingStatus = (int)listing.Status,
                    ListingImageUrl = listing.ImageUrl,
                    ListingBusinessId = listing.BusinessId,
                    ListingSeller = listing.Business?.BusinessName,
                    OtherBusinessId = m.OtherId,
                    OtherBusinessName = others.TryGetValue(m.OtherId, out var other) ? other.BusinessName : "Unknown",
                    LastMessage = m.Content,
                    LastMessageAt = m.CreatedAt,
                    LastMessageIsMe = m.IsMe
                };
            })
            .ToList();

        return Ok(conversations);
    }
}
