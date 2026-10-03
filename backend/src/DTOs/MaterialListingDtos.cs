namespace EcoLoop.Api.DTOs;

// Request to create a new listing
public class CreateMaterialListingRequest
{
    public Guid BusinessId { get; set; }
    // Optional verified Business Hub profile of the poster to sell as.
    public Guid? PostedAsBusinessId { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Category { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public string Quantity { get; set; } = string.Empty;
    public string Unit { get; set; } = string.Empty;
    public string Location { get; set; } = string.Empty;
    public decimal Price { get; set; }
    public string PriceUnit { get; set; } = string.Empty;
    public string DeliveryMethod { get; set; } = string.Empty;
    public bool SellerDeliveryAvailable { get; set; }
    public string? Availability { get; set; }
    public string? Condition { get; set; }
    public int Type { get; set; } // 0 = IHave, 1 = INeed
    public string? ImageUrl { get; set; }
    public List<string> ImageUrls { get; set; } = [];
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
    public bool SellerDeliveryAvailable { get; set; }
    public string? Availability { get; set; }
    public string? Condition { get; set; }
    public string? ImageUrl { get; set; }
    // Current photos to keep, in display order; null leaves photos unchanged.
    public List<string>? KeepImageUrls { get; set; }
}

// Compact DTO for list/grid views
public class MaterialListingListDto
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
    public Guid? PostedAsBusinessId { get; set; }
    public string? Seller { get; set; }
    public string? SellerLogoUrl { get; set; }
    public bool SellerIsVerified { get; set; }
    public int Type { get; set; }
    public int Status { get; set; }
    public DateTime CreatedAt { get; set; }
    public string? ImageUrl { get; set; }
    public List<string> ImageUrls { get; set; } = [];
    public bool SellerDeliveryAvailable { get; set; }
    public string? Availability { get; set; }
    public string? Condition { get; set; }
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
    public bool SellerDeliveryAvailable { get; set; }
    public string? Availability { get; set; }
    public string? Condition { get; set; }
    public Guid? PostedAsBusinessId { get; set; }
    public string? Seller { get; set; }
    public string? SellerLogoUrl { get; set; }
    public bool SellerIsVerified { get; set; }
    public int Type { get; set; }
    public int Status { get; set; }
    public DateTime CreatedAt { get; set; }
    public string? ImageUrl { get; set; }
    public List<string> ImageUrls { get; set; } = [];
}
