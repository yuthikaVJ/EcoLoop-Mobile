namespace EcoLoop.Api.DTOs;

// Request to create a new listing
public class CreateMaterialListingRequest
{
    public Guid BusinessId { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Category { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public string Quantity { get; set; } = string.Empty;
    public string Unit { get; set; } = string.Empty;
    public string Location { get; set; } = string.Empty;
    public decimal Price { get; set; }
    public string PriceUnit { get; set; } = string.Empty;
    public string DeliveryMethod { get; set; } = string.Empty;
    public int Type { get; set; } // 0 = IHave, 1 = INeed
}

// Request to update an existing listing
public class UpdateMaterialListingRequest
{
    public string Title { get; set; } = string.Empty;
    public string Category { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public string Quantity { get; set; } = string.Empty;
    public string Unit { get; set; } = string.Empty;
    public string Location { get; set; } = string.Empty;
    public decimal Price { get; set; }
    public string PriceUnit { get; set; } = string.Empty;
    public string DeliveryMethod { get; set; } = string.Empty;
}

// Compact DTO for list/grid views
public class MaterialListingListDto
{
    public Guid Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Category { get; set; } = string.Empty;
    public string Quantity { get; set; } = string.Empty;
    public string Location { get; set; } = string.Empty;
    public decimal Price { get; set; }
    public string PriceUnit { get; set; } = string.Empty;
    public string? Seller { get; set; }
    public bool SellerIsVerified { get; set; }
    public int Type { get; set; }
    public int Status { get; set; }
    public DateTime CreatedAt { get; set; }
}

// Full DTO for details page
public class MaterialListingDetailsDto
{
    public Guid Id { get; set; }
    public Guid BusinessId { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Category { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public string Quantity { get; set; } = string.Empty;
    public string Unit { get; set; } = string.Empty;
    public string Location { get; set; } = string.Empty;
    public decimal Price { get; set; }
    public string PriceUnit { get; set; } = string.Empty;
    public string DeliveryMethod { get; set; } = string.Empty;
    public string? Seller { get; set; }
    public bool SellerIsVerified { get; set; }
    public int Type { get; set; }
    public int Status { get; set; }
    public DateTime CreatedAt { get; set; }
}
