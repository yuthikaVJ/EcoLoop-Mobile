namespace EcoLoop.Api.Models;

public class DeviceToken
{
    public Guid Id { get; set; } = Guid.NewGuid();
    
    public Guid BusinessId { get; set; }
    public Business? Business { get; set; }

    public string Token { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
