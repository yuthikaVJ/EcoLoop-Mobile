namespace EcoLoop.Api.Models;

public class MaterialTransactionStatusHistory
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid MaterialTransactionId { get; set; }
    public MaterialTransactionStatus Status { get; set; }
    public Guid? ChangedByBusinessId { get; set; }
    public string? Note { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public MaterialTransaction? MaterialTransaction { get; set; }
    public Business? ChangedByBusiness { get; set; }
}
