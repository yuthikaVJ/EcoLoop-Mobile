namespace EcoLoop.Api.Models;

public class ChatMessage
{
    public Guid Id { get; set; } = Guid.NewGuid();
    
    // The specific material listing this chat is about
    public Guid ListingId { get; set; }
    public MaterialListing? Listing { get; set; }

    public Guid SenderId { get; set; }
    public Business? Sender { get; set; }

    public Guid ReceiverId { get; set; }
    public Business? Receiver { get; set; }

    public string Content { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
