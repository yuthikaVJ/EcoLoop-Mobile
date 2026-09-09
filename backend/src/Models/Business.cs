namespace EcoLoop.Api.Models;

public class Business
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public string BusinessName { get; set; } = string.Empty;
    public string? LogoUrl { get; set; }
    public bool IsVerified { get; set; }
}