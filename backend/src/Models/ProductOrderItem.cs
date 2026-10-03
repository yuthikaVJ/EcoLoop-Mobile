namespace EcoLoop.Api.Models;

public class ProductOrderItem
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid ProductOrderId { get; set; }
    public Guid ProductId { get; set; }
    public string ProductName { get; set; } = string.Empty;
    public int Quantity { get; set; }
    public decimal UnitPrice { get; set; }
    public decimal LineTotal { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public ProductOrder? ProductOrder { get; set; }
    public Product? Product { get; set; }
}
