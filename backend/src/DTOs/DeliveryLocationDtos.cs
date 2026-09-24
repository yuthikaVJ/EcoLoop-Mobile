namespace EcoLoop.Api.DTOs;

public class SaveDeliveryLocationRequest
{
    // Temporary identity contract, replaced by the group's authenticated business claim.
    public Guid BusinessId { get; set; }
    public string Label { get; set; } = string.Empty;
    public string Address { get; set; } = string.Empty;
    public double? Latitude { get; set; }
    public double? Longitude { get; set; }
    public DateTime? ExpectedUpdatedAt { get; set; }
}

public record DeliveryLocationDto(Guid Id, string Label, string Address, double? Latitude,
    double? Longitude, DateTime CreatedAt, DateTime UpdatedAt);
