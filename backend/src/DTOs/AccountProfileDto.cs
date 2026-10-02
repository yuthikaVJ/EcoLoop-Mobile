namespace EcoLoop.Api.DTOs;

// Personal details of the signed-in account. Business details live in
// Business Hub profiles (see BusinessDtos.cs).
public class AccountProfileDto
{
    public Guid Id { get; set; }
    public string BusinessName { get; set; } = string.Empty;
    public string? Email { get; set; }
    public string? LogoUrl { get; set; }
    public string? PhoneNumber { get; set; }
    public string? Address { get; set; }
    public DateTime CreatedAt { get; set; }
    public bool IsVerified { get; set; }
}
