namespace EcoLoop.Api.Models;

public class ProductCategory
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public bool IsActive { get; set; } = true;

    public List<Product> Products { get; set; } = [];
}