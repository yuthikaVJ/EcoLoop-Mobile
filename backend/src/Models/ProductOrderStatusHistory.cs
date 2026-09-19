namespace EcoLoop.Api.Models;

public class ProductOrderStatusHistory
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid ProductOrderId { get; set; }
    public ProductOrderStatus Status { get; set; }
    public Guid? ChangedByBusinessId { get; set; }
    public string? Note { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public ProductOrder? ProductOrder { get; set; }
    public Business? ChangedByBusiness { get; set; }
}
