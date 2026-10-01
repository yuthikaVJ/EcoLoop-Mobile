namespace EcoLoop.Api.Models;

public class Delivery
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid? MaterialTransactionId { get; set; }
    public Guid? ProductOrderId { get; set; }
    public DeliveryMethod Method { get; set; } = DeliveryMethod.SelfPickup;
    public string? Location { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? UpdatedAt { get; set; }

    // Seller Delivery progress: the seller is the driver (no EcoLoop fleet).
    public DeliveryStatus Status { get; set; } = DeliveryStatus.NotStarted;
    public double? CurrentLatitude { get; set; }
    public double? CurrentLongitude { get; set; }
    public DateTime? LocationUpdatedAt { get; set; }

    public MaterialTransaction? MaterialTransaction { get; set; }
    public ProductOrder? ProductOrder { get; set; }
}

public enum DeliveryMethod
{
    SelfPickup = 0,
    SellerDelivery = 1
}

public enum DeliveryStatus
{
    NotStarted = 0,
    OnTheWay = 1,
    Delivered = 2
}
