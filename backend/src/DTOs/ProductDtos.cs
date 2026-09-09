namespace EcoLoop.Api.DTOs;

public class CreateProductRequest
{
    public Guid CategoryId { get; set; }
    public Guid BusinessId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public string MaterialType { get; set; } = string.Empty;
    public decimal Price { get; set; }
}

public class UpdateProductRequest
{
    public Guid CategoryId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public string MaterialType { get; set; } = string.Empty;
    public decimal Price { get; set; }
}

public class ProductListDto
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public string MaterialType { get; set; } = string.Empty;
    public decimal Price { get; set; }
    public string? Category { get; set; }
    public string? Seller { get; set; }
    public bool SellerIsVerified { get; set; }
    public int AvailableQuantity { get; set; }
    public string? PrimaryImageUrl { get; set; }
}

public class ProductDetailsDto
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public string MaterialType { get; set; } = string.Empty;
    public decimal Price { get; set; }
    public string? Category { get; set; }
    public string? Seller { get; set; }
    public bool SellerIsVerified { get; set; }
    public int AvailableQuantity { get; set; }
    public List<string> Images { get; set; } = [];
}