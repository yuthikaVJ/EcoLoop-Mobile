namespace EcoLoop.Api.DTOs;

public class CreateMaterialTransactionRequest
{
    public Guid MaterialListingId { get; set; }
    public Guid BuyerBusinessId { get; set; }
    public Guid SellerBusinessId { get; set; }
    public decimal Quantity { get; set; }
    public string Unit { get; set; } = string.Empty;
    public decimal UnitPrice { get; set; }
    public DeliveryInputDto Delivery { get; set; } = new();
}

public class TransactionActionRequest
{
    // Temporary until the team's authentication/JWT component supplies the acting business claim.
    public Guid ActingBusinessId { get; set; }
    public string? Note { get; set; }
}

public class UpdateMaterialTransactionRequest
{
    public Guid ActingBusinessId { get; set; }
    public decimal Quantity { get; set; }
    public string Unit { get; set; } = string.Empty;
    public decimal UnitPrice { get; set; }
    public DateTime? ExpectedUpdatedAt { get; set; }
}

public class UpdateDeliveryLocationRequest
{
    public Guid ActingBusinessId { get; set; }
    public string Location { get; set; } = string.Empty;
    public DateTime? ExpectedUpdatedAt { get; set; }
}

public class DeliveryInputDto
{
    public int Method { get; set; }
    public string? Location { get; set; }
}

public class DeliveryDto
{
    public Guid Id { get; set; }
    public int Method { get; set; }
    public string MethodName { get; set; } = string.Empty;
    public string? Location { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
    public int Status { get; set; }
    public string StatusName { get; set; } = string.Empty;
    public double? CurrentLatitude { get; set; }
    public double? CurrentLongitude { get; set; }
    public DateTime? LocationUpdatedAt { get; set; }
}

public class StatusHistoryDto
{
    public int Status { get; set; }
    public string StatusName { get; set; } = string.Empty;
    public Guid? ChangedByBusinessId { get; set; }
    public string? ChangedByBusinessName { get; set; }
    public string? Note { get; set; }
    public DateTime CreatedAt { get; set; }
}

public class MaterialTransactionListDto
{
    public Guid Id { get; set; }
    public Guid MaterialListingId { get; set; }
    public string ListingTitle { get; set; } = string.Empty;
    public string Buyer { get; set; } = string.Empty;
    public string Seller { get; set; } = string.Empty;
    public decimal Quantity { get; set; }
    public string Unit { get; set; } = string.Empty;
    public decimal TotalAmount { get; set; }
    public int Status { get; set; }
    public string StatusName { get; set; } = string.Empty;
    public int DeliveryMethod { get; set; }
    public DateTime CreatedAt { get; set; }
}

public class MaterialTransactionDetailsDto : MaterialTransactionListDto
{
    public Guid BuyerBusinessId { get; set; }
    public Guid SellerBusinessId { get; set; }
    // 0 = I Have (the seller accepts), 1 = I Need (an offer: the requester, i.e. the buyer, accepts).
    public int ListingType { get; set; }
    public decimal UnitPrice { get; set; }
    public DateTime? UpdatedAt { get; set; }
    public DeliveryDto? Delivery { get; set; }
    public List<StatusHistoryDto> StatusHistory { get; set; } = [];
}
