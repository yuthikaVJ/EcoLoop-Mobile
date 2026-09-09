namespace EcoLoop.Api.Models;

public class Inventory
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid ProductId { get; set; }
    public int Quantity { get; set; }
    public bool IsAvailable { get; set; } = true;

    public Product? Product { get; set; }

    public int AvailableQuantity => IsAvailable ? Quantity : 0;
}