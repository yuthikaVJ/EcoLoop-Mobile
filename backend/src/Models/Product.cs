namespace EcoLoop.Api.Models;

public class Product
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid CategoryId { get; set; }
    public Guid BusinessId { get; set; } 

    public string Name { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public string MaterialType { get; set; } = string.Empty;
    public decimal Price { get; set; }
    public bool IsActive { get; set; } = true;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public ProductCategory? Category { get; set; }
    public Business? Business { get; set; }
    public Inventory? Inventory { get; set; }
    public List<ProductImage> Images { get; set; } = [];


}