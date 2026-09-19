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

    public MaterialTransaction? MaterialTransaction { get; set; }
    public ProductOrder? ProductOrder { get; set; }
}

public enum DeliveryMethod
{
    SelfPickup = 0,
    SellerDelivery = 1
}
