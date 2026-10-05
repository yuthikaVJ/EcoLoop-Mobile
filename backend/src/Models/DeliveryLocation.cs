using System.ComponentModel.DataAnnotations;

namespace EcoLoop.Api.Models;

// Saved address book entry. Deliveries keep a text snapshot, so deletion cannot erase order history.
public class DeliveryLocation
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid BusinessId { get; set; }
    public Business? Business { get; set; }
    public string Label { get; set; } = string.Empty;
    public string Address { get; set; } = string.Empty;
    public double? Latitude { get; set; }
    public double? Longitude { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    [ConcurrencyCheck]
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
}
