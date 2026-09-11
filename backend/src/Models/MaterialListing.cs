namespace EcoLoop.Api.Models;

public class MaterialListing
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid BusinessId { get; set; }

    public string Title { get; set; } = string.Empty;
    public string Category { get; set; } = string.Empty;      // e.g. "PLASTICS", "PAPER", "METALS"
    public string Description { get; set; } = string.Empty;
    public string Quantity { get; set; } = string.Empty;       // e.g. "10"
    public string Unit { get; set; } = string.Empty;           // e.g. "Tons", "Kgs", "Units", "Bales"
    public string Location { get; set; } = string.Empty;
    public decimal Price { get; set; }
    public string PriceUnit { get; set; } = string.Empty;      // e.g. "Ton", "Kg", "Unit"
    public string DeliveryMethod { get; set; } = string.Empty; // e.g. "Self Pickup", "Seller Delivery"

    public ListingType Type { get; set; } = ListingType.IHave;
    public ListingStatus Status { get; set; } = ListingStatus.Active;

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? UpdatedAt { get; set; }

    // Navigation
    public Business? Business { get; set; }
}

public enum ListingType
{
    IHave = 0,
    INeed = 1
}

public enum ListingStatus
{
    Active = 0,
    Completed = 1,
    Deleted = 2
}
