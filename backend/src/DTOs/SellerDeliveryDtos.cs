namespace EcoLoop.Api.DTOs;

// One Seller Delivery job as the seller (the "driver") sees it.
public class SellerDeliveryDto
{
    public Guid Id { get; set; }
    public string Kind { get; set; } = string.Empty; // "material" or "product"
    public Guid ParentId { get; set; } // material transaction or product order
    public string Title { get; set; } = string.Empty;
    public string Buyer { get; set; } = string.Empty;
    public string? Destination { get; set; }
    public decimal TotalAmount { get; set; }
    public int ParentStatus { get; set; }
    public string ParentStatusName { get; set; } = string.Empty;
    public int Status { get; set; }
    public string StatusName { get; set; } = string.Empty;
    public double? CurrentLatitude { get; set; }
    public double? CurrentLongitude { get; set; }
    public DateTime? LocationUpdatedAt { get; set; }
    public DateTime CreatedAt { get; set; }
}

public class DeliveryPositionRequest
{
    public double Latitude { get; set; }
    public double Longitude { get; set; }
}
