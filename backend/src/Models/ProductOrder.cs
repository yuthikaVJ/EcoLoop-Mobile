using System.ComponentModel.DataAnnotations;

namespace EcoLoop.Api.Models;

public class ProductOrder
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid BuyerBusinessId { get; set; }
    public Guid SellerBusinessId { get; set; }
    [ConcurrencyCheck]
    public ProductOrderStatus Status { get; set; } = ProductOrderStatus.Placed;
    public decimal TotalAmount { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    [ConcurrencyCheck]
    public DateTime? UpdatedAt { get; set; }

    public Business? BuyerBusiness { get; set; }
    public Business? SellerBusiness { get; set; }
    public Delivery? Delivery { get; set; }
    public List<ProductOrderItem> Items { get; set; } = [];
    public List<ProductOrderStatusHistory> StatusHistory { get; set; } = [];
}

public enum ProductOrderStatus
{
    Placed = 0,
    Confirmed = 1,
    Processing = 2,
    Ready = 3,
    Completed = 4,
    Delivered = 5,
    Cancelled = 6
}
