using EcoLoop.Api.Data;
using EcoLoop.Api.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;
using EcoLoop.Api.Services;

namespace EcoLoop.Api.Hubs;

[Authorize]
public class ChatHub : Hub
{
    private readonly EcoLoopDbContext _db;
    private readonly NotificationService _notificationService;

    public ChatHub(EcoLoopDbContext db, NotificationService notificationService)
    {
        _db = db;
        _notificationService = notificationService;
    }

    public async Task SendMessage(Guid listingId, Guid receiverId, string content)
    {
        var senderIdClaim = Context.User?.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(senderIdClaim) || !Guid.TryParse(senderIdClaim, out var senderId))
        {
            throw new HubException("Unauthorized sender.");
        }

        content = content?.Trim() ?? string.Empty;
        if (content.Length == 0) throw new HubException("Message cannot be empty.");
        if (receiverId == senderId) throw new HubException("You cannot message yourself.");

        var message = new ChatMessage
        {
            ListingId = listingId,
            SenderId = senderId,
            ReceiverId = receiverId,
            Content = content,
            CreatedAt = DateTime.UtcNow
        };

        _db.ChatMessages.Add(message);
        await _db.SaveChangesAsync();

        // Plain payload (not the EF entity) with the sender, so each client can tell
        // its own messages from the other person's.
        var payload = new
        {
            id = message.Id,
            listingId = message.ListingId,
            senderId = message.SenderId,
            receiverId = message.ReceiverId,
            content = message.Content,
            createdAt = message.CreatedAt
        };

        // Broadcast to the receiver
        await Clients.User(receiverId.ToString()).SendAsync("ReceiveMessage", payload);

        // Also send back to the caller: it replaces their optimistic copy with the saved one.
        await Clients.Caller.SendAsync("ReceiveMessage", payload);

        // Send Push Notification to the receiver
        var receiverTokens = await _db.DeviceTokens
            .Where(d => d.BusinessId == receiverId)
            .Select(d => d.Token)
            .ToListAsync();
            
        if (receiverTokens.Any())
        {
            var sender = await _db.Businesses.FindAsync(senderId);
            var senderName = sender?.BusinessName ?? "Someone";
            
            await _notificationService.SendPushNotificationAsync(
                receiverTokens,
                "New Message",
                $"{senderName}: {content}",
                new Dictionary<string, string>
                {
                    { "type", "chat_message" },
                    { "listingId", listingId.ToString() },
                    { "senderId", senderId.ToString() }
                }
            );
        }
    }
}
