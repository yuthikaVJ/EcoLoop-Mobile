namespace EcoLoop.Api.DTOs;

public class CreateInventoryRequest
{
    public int Quantity { get; set; }
}

public class UpdateInventoryRequest
{
    public int Quantity { get; set; }
    public bool IsAvailable { get; set; }
}