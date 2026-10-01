using System.ComponentModel.DataAnnotations;

namespace EcoLoop.Api.DTOs;

public class UpdateBusinessProfileRequest
{
    [Required]
    public string BusinessName { get; set; } = string.Empty;
    public string? PhoneNumber { get; set; }
    public string? Address { get; set; }
    public string? IndustryType { get; set; }
    public string? Description { get; set; }
}
