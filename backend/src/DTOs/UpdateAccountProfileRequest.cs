using System.ComponentModel.DataAnnotations;

namespace EcoLoop.Api.DTOs;

public class UpdateAccountProfileRequest
{
    [Required]
    public string BusinessName { get; set; } = string.Empty;
    public string? PhoneNumber { get; set; }
    public string? Address { get; set; }
}
