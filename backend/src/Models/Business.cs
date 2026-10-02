namespace EcoLoop.Api.Models;

// A row is either a signed-in account (created by Google login, GoogleId set)
// or a Business Hub profile owned by an account (UserId = the account's Id).
public class Business
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public string BusinessName { get; set; } = string.Empty;
    public string? Email { get; set; }
    public string? GoogleId { get; set; }
    public string? LogoUrl { get; set; }
    public string? CoverPhotoUrl { get; set; }
    public string? PhoneNumber { get; set; }
    public string? Address { get; set; }
    public string? IndustryType { get; set; }
    public string? RegistrationNumber { get; set; }
    public string? Bio { get; set; }
    public string? Description { get; set; }
    public string? WebsiteUrl { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? UpdatedAt { get; set; }
    public bool IsVerified { get; set; }
    public string Status { get; set; } = "Unverified";
    public Guid? UserId { get; set; }
}
