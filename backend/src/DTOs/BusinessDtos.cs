using System.ComponentModel.DataAnnotations;

namespace EcoLoop.Api.DTOs;

public class CreateBusinessProfileRequest
{
    [Required(ErrorMessage = "Business name is required.")]
    [StringLength(150, MinimumLength = 2, ErrorMessage = "Business name must be between 2 and 150 characters.")]
    public string BusinessName { get; set; } = string.Empty;

    [Required(ErrorMessage = "Business type is required.")]
    [StringLength(100, ErrorMessage = "Business type must not exceed 100 characters.")]
    public string BusinessType { get; set; } = string.Empty;

    [Required(ErrorMessage = "Registration number is required.")]
    [StringLength(50, ErrorMessage = "Registration number must not exceed 50 characters.")]
    public string RegistrationNumber { get; set; } = string.Empty;

    [StringLength(1000, ErrorMessage = "Description must not exceed 1000 characters.")]
    public string? Description { get; set; }

    [Required(ErrorMessage = "Email is required.")]
    [EmailAddress(ErrorMessage = "A valid email address is required.")]
    [StringLength(150, ErrorMessage = "Email must not exceed 150 characters.")]
    public string Email { get; set; } = string.Empty;

    [Required(ErrorMessage = "Phone number is required.")]
    [Phone(ErrorMessage = "A valid phone number is required.")]
    [StringLength(30, ErrorMessage = "Phone number must not exceed 30 characters.")]
    public string Phone { get; set; } = string.Empty;

    [Required(ErrorMessage = "Address is required.")]
    [StringLength(300, ErrorMessage = "Address must not exceed 300 characters.")]
    public string Address { get; set; } = string.Empty;

    [Url(ErrorMessage = "Please provide a valid website URL.")]
    [StringLength(300, ErrorMessage = "Website URL must not exceed 300 characters.")]
    public string? WebsiteUrl { get; set; }

    [Url(ErrorMessage = "Please provide a valid logo URL.")]
    [StringLength(500, ErrorMessage = "Logo URL must not exceed 500 characters.")]
    public string? LogoUrl { get; set; }

    public Guid? UserId { get; set; }
}

public class BusinessProfileDto
{
    public Guid Id { get; set; }
    public string BusinessName { get; set; } = string.Empty;
    public string BusinessType { get; set; } = string.Empty;
    public string RegistrationNumber { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string Email { get; set; } = string.Empty;
    public string Phone { get; set; } = string.Empty;
    public string Address { get; set; } = string.Empty;
    public string? WebsiteUrl { get; set; }
    public string? LogoUrl { get; set; }
    public bool IsVerified { get; set; }
    public string Status { get; set; } = "Unverified";
    public Guid? UserId { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
}
