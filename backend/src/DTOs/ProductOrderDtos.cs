namespace EcoLoop.Api.DTOs;

public class CreateProductOrderRequest
{
    // Temporary until the team's authentication/JWT component supplies the buyer business claim.
    public Guid BuyerBusinessId { get; set; }
    public List<CreateProductOrderItemRequest> Items { get; set; } = [];
    public DeliveryInputDto Delivery { get; set; } = new();
}

public class CreateProductOrderItemRequest
{
    public Guid ProductId { get; set; }
    public int Quantity { get; set; }
}

public class ProductOrderItemDto
{
    public Guid ProductId { get; set; }
    public string ProductName { get; set; } = string.Empty;
    public int Quantity { get; set; }
    public decimal UnitPrice { get; set; }
    public decimal LineTotal { get; set; }
}

public class ProductOrderListDto
{
    public Guid Id { get; set; }
    public string Buyer { get; set; } = string.Empty;
    public string Seller { get; set; } = string.Empty;
    public int ItemCount { get; set; }
    public decimal TotalAmount { get; set; }
    public int Status { get; set; }
    public string StatusName { get; set; } = string.Empty;
    public int DeliveryMethod { get; set; }
    public DateTime CreatedAt { get; set; }
}

public class ProductOrderDetailsDto : ProductOrderListDto
{
    public Guid BuyerBusinessId { get; set; }
    public Guid SellerBusinessId { get; set; }
    public DateTime? UpdatedAt { get; set; }
    public List<ProductOrderItemDto> Items { get; set; } = [];
    public DeliveryDto? Delivery { get; set; }
    public List<StatusHistoryDto> StatusHistory { get; set; } = [];
}
