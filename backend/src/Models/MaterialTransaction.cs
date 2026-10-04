using System.ComponentModel.DataAnnotations;

namespace EcoLoop.Api.Models;

public class MaterialTransaction
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid MaterialListingId { get; set; }
    public Guid BuyerBusinessId { get; set; }
    public Guid SellerBusinessId { get; set; }
    public decimal Quantity { get; set; }
    public string Unit { get; set; } = string.Empty;
    public decimal UnitPrice { get; set; }
    public decimal TotalAmount { get; set; }
    [ConcurrencyCheck]
    public MaterialTransactionStatus Status { get; set; } = MaterialTransactionStatus.Pending;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    [ConcurrencyCheck]
    public DateTime? UpdatedAt { get; set; }

    public MaterialListing? MaterialListing { get; set; }
    public Business? BuyerBusiness { get; set; }
    public Business? SellerBusiness { get; set; }
    public Delivery? Delivery { get; set; }
    public List<MaterialTransactionStatusHistory> StatusHistory { get; set; } = [];
}

public enum MaterialTransactionStatus
{
    Pending = 0,
    Accepted = 1,
    Rejected = 2,
    Processing = 3,
    Ready = 4,
    Completed = 5,
    Cancelled = 6
}
