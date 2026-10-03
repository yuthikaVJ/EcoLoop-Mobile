namespace EcoLoop.Api.Models;

public class RefreshToken
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public string Token { get; set; } = string.Empty;
    public string JwtId { get; set; } = string.Empty; // To match with the Access Token's JTI claim
    public DateTime CreationDate { get; set; } = DateTime.UtcNow;
    public DateTime ExpiryDate { get; set; }
    public bool Used { get; set; }
    public bool Invalidated { get; set; }
    
    public Guid BusinessId { get; set; }
    public Business Business { get; set; } = null!;
}
