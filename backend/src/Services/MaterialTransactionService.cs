using EcoLoop.Api.Data;
using EcoLoop.Api.DTOs;
using EcoLoop.Api.Models;
using EcoLoop.Api.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace EcoLoop.Api.Services;

public class MaterialTransactionService : IMaterialTransactionService
{
    private readonly EcoLoopDbContext _db;

    public MaterialTransactionService(EcoLoopDbContext db) => _db = db;

    public async Task<(MaterialTransactionDetailsDto? Data, string? Error)> CreateAsync(CreateMaterialTransactionRequest request)
    {
        var validation = TransactionRules.ValidateTerms(request.Quantity, request.Unit, request.UnitPrice)
            ?? TransactionRules.ValidateDelivery(request.Delivery);
        if (validation != null) return (null, validation);
        if (request.Quantity <= 0) return (null, "Quantity must be greater than zero.");
        if (request.UnitPrice < 0) return (null, "Unit price cannot be negative.");
        if (string.IsNullOrWhiteSpace(request.Unit)) return (null, "Unit is required.");
        if (request.BuyerBusinessId == request.SellerBusinessId) return (null, "Buyer and seller must be different businesses.");
        if (!Enum.IsDefined(typeof(DeliveryMethod), request.Delivery.Method)) return (null, "Invalid delivery method.");

        var listing = await _db.MaterialListings.AsNoTracking()
            .FirstOrDefaultAsync(x => x.Id == request.MaterialListingId && x.Status == ListingStatus.Active);
        if (listing == null) return (null, "Material listing was not found or is not active.");

        var partiesExist = await _db.Businesses.CountAsync(x => x.Id == request.BuyerBusinessId || x.Id == request.SellerBusinessId) == 2;
        if (!partiesExist) return (null, "Buyer or seller business was not found.");

        if (listing.Type == ListingType.IHave && listing.BusinessId != request.SellerBusinessId)
            return (null, "The listing owner must be the seller for an I Have listing.");
        if (listing.Type == ListingType.INeed && listing.BusinessId != request.BuyerBusinessId)
            return (null, "The listing owner must be the buyer for an I Need listing.");

        var method = (DeliveryMethod)request.Delivery.Method;
        if (method == DeliveryMethod.SellerDelivery && !listing.SellerDeliveryAvailable)
            return (null, "Seller delivery is not available for this listing.");
        if (method == DeliveryMethod.SellerDelivery && string.IsNullOrWhiteSpace(request.Delivery.Location))
            return (null, "A delivery location is required for seller delivery.");

        var now = DateTime.UtcNow;
        var transaction = new MaterialTransaction
        {
            MaterialListingId = listing.Id,
            BuyerBusinessId = request.BuyerBusinessId,
            SellerBusinessId = request.SellerBusinessId,
            Quantity = request.Quantity,
            Unit = request.Unit.Trim(),
            UnitPrice = request.UnitPrice,
            TotalAmount = decimal.Round(request.Quantity * request.UnitPrice, 2),
            Status = MaterialTransactionStatus.Pending,
            CreatedAt = now,
            Delivery = new Delivery
            {
                Method = method,
                Location = method == DeliveryMethod.SelfPickup && listing.Type == ListingType.IHave
                    ? CleanLocation(listing.Location) : CleanLocation(request.Delivery.Location),
                CreatedAt = now
            },
            StatusHistory =
            [
                new MaterialTransactionStatusHistory
                {
                    Status = MaterialTransactionStatus.Pending,
                    ChangedByBusinessId = request.BuyerBusinessId,
                    Note = "Transaction requested",
                    CreatedAt = now
                }
            ]
        };

        _db.MaterialTransactions.Add(transaction);
        await _db.SaveChangesAsync();
        return (await GetByIdAsync(transaction.Id), null);
    }

    public async Task<MaterialTransactionDetailsDto?> GetByIdAsync(Guid id)
    {
        var item = await BaseQuery().AsNoTracking().FirstOrDefaultAsync(x => x.Id == id);
        return item == null ? null : MapDetails(item);
    }

    public Task<object> GetBuyerHistoryAsync(Guid buyerBusinessId, int page, int pageSize) =>
        GetHistoryAsync(x => x.BuyerBusinessId == buyerBusinessId, page, pageSize);

    public Task<object> GetSellerHistoryAsync(Guid sellerBusinessId, int page, int pageSize) =>
        GetHistoryAsync(x => x.SellerBusinessId == sellerBusinessId, page, pageSize);

    public async Task<(MaterialTransactionDetailsDto? Data, string? Error)> ChangeStatusAsync(
        Guid id, Guid actingBusinessId, MaterialTransactionStatus status, string? note)
    {
        if (note?.Length > 500) return (null, "Note must not exceed 500 characters.");
        var item = await _db.MaterialTransactions.Include(x => x.Delivery).FirstOrDefaultAsync(x => x.Id == id);
        if (item == null) return (null, "Material transaction was not found.");
        if (item.Status is MaterialTransactionStatus.Rejected or MaterialTransactionStatus.Completed or MaterialTransactionStatus.Cancelled)
            return (null, "A terminal transaction cannot be changed.");
        if (actingBusinessId != item.BuyerBusinessId && actingBusinessId != item.SellerBusinessId)
            return (null, "The acting business is not a party to this transaction.");

        var sellerOnly = status is MaterialTransactionStatus.Accepted or MaterialTransactionStatus.Rejected
            or MaterialTransactionStatus.Processing or MaterialTransactionStatus.Ready;
        if (sellerOnly && actingBusinessId != item.SellerBusinessId)
            return (null, "Only the seller can perform this action.");
        if (!IsValidTransition(item.Status, status))
            return (null, $"Cannot change transaction from {item.Status} to {status}.");
        if (status == MaterialTransactionStatus.Ready && string.IsNullOrWhiteSpace(item.Delivery?.Location))
            return (null, "Set the pickup/delivery address before marking this transaction ready.");

        var now = DateTime.UtcNow;
        item.Status = status;
        item.UpdatedAt = now;
        _db.MaterialTransactionStatusHistories.Add(new MaterialTransactionStatusHistory
        {
            MaterialTransactionId = item.Id,
            Status = status,
            ChangedByBusinessId = actingBusinessId,
            Note = string.IsNullOrWhiteSpace(note) ? null : note.Trim(),
            CreatedAt = now
        });
        await _db.SaveChangesAsync();
        return (await GetByIdAsync(id), null);
    }

    public async Task<MaterialTransactionDetailsDto> UpdateDetailsAsync(Guid id, UpdateMaterialTransactionRequest request)
    {
        var item = await _db.MaterialTransactions.SingleOrDefaultAsync(x => x.Id == id)
            ?? throw new TransactionRuleException(404, "Material transaction not found.");
        if (request.ActingBusinessId != item.BuyerBusinessId)
            throw new TransactionRuleException(403, "Only the buyer can revise a request.");
        if (item.Status != MaterialTransactionStatus.Pending)
            throw new TransactionRuleException(409, "Only pending requests can be revised.");
        if (item.UpdatedAt != request.ExpectedUpdatedAt)
            throw new TransactionRuleException(409, "The request changed. Reload it before editing.");
        var error = TransactionRules.ValidateTerms(request.Quantity, request.Unit, request.UnitPrice);
        if (error != null) throw new TransactionRuleException(400, error);
        var oldTerms = $"{item.Quantity} {item.Unit} at {item.UnitPrice}";
        item.Quantity = request.Quantity;
        item.Unit = request.Unit.Trim();
        item.UnitPrice = request.UnitPrice;
        item.TotalAmount = decimal.Round(item.Quantity * item.UnitPrice, 2);
        item.UpdatedAt = DateTime.UtcNow;
        _db.MaterialTransactionStatusHistories.Add(new()
        {
            MaterialTransactionId = id, Status = item.Status, ChangedByBusinessId = request.ActingBusinessId,
            Note = $"Request revised from {oldTerms} to {item.Quantity} {item.Unit} at {item.UnitPrice}; awaiting seller acceptance.",
            CreatedAt = item.UpdatedAt.Value
        });
        await _db.SaveChangesAsync();
        return (await GetByIdAsync(id))!;
    }

    public async Task<MaterialTransactionDetailsDto> UpdateLocationAsync(Guid id, UpdateDeliveryLocationRequest request)
    {
        var item = await _db.MaterialTransactions.Include(x => x.Delivery).SingleOrDefaultAsync(x => x.Id == id)
            ?? throw new TransactionRuleException(404, "Material transaction not found.");
        if (item.Delivery == null) throw new TransactionRuleException(404, "Delivery not found.");
        ValidateLocationEdit(request, item.Delivery, item.BuyerBusinessId, item.SellerBusinessId,
            item.Status is MaterialTransactionStatus.Pending or MaterialTransactionStatus.Accepted or MaterialTransactionStatus.Processing,
            item.UpdatedAt);
        item.Delivery.Location = request.Location.Trim();
        item.UpdatedAt = item.Delivery.UpdatedAt = DateTime.UtcNow;
        _db.MaterialTransactionStatusHistories.Add(new()
        {
            MaterialTransactionId = id, Status = item.Status, ChangedByBusinessId = request.ActingBusinessId,
            Note = "Pickup/delivery location updated.", CreatedAt = item.UpdatedAt.Value
        });
        await _db.SaveChangesAsync();
        return (await GetByIdAsync(id))!;
    }

    internal static void ValidateLocationEdit(UpdateDeliveryLocationRequest request, Delivery delivery,
        Guid buyer, Guid seller, bool editable, DateTime? updatedAt)
    {
        var owner = delivery.Method == DeliveryMethod.SelfPickup ? seller : buyer;
        if (request.ActingBusinessId != owner)
            throw new TransactionRuleException(403, "Only the seller can change pickup addresses; only the buyer can change delivery destinations.");
        if (!editable) throw new TransactionRuleException(409, "Location cannot change once ready or terminal.");
        if (updatedAt != request.ExpectedUpdatedAt)
            throw new TransactionRuleException(409, "This record changed. Reload it before editing.");
        if (string.IsNullOrWhiteSpace(request.Location) || request.Location.Length > 500)
            throw new TransactionRuleException(400, "Location must contain 1 to 500 characters.");
    }

    private async Task<object> GetHistoryAsync(
        System.Linq.Expressions.Expression<Func<MaterialTransaction, bool>> predicate,
        int page, int pageSize)
    {
        page = Math.Clamp(page, 1, 1000000);
        pageSize = Math.Clamp(pageSize, 1, 100);
        var query = BaseQuery().AsNoTracking().Where(predicate).OrderByDescending(x => x.CreatedAt);
        var totalItems = await query.CountAsync();
        var entities = await query.Skip((page - 1) * pageSize).Take(pageSize).ToListAsync();
        return new
        {
            items = entities.Select(MapList).ToList(),
            page,
            pageSize,
            totalItems,
            totalPages = (int)Math.Ceiling((double)totalItems / pageSize)
        };
    }

    private IQueryable<MaterialTransaction> BaseQuery() => _db.MaterialTransactions
        .Include(x => x.MaterialListing)
        .Include(x => x.BuyerBusiness)
        .Include(x => x.SellerBusiness)
        .Include(x => x.Delivery)
        .Include(x => x.StatusHistory).ThenInclude(x => x.ChangedByBusiness);

    private static bool IsValidTransition(MaterialTransactionStatus current, MaterialTransactionStatus next) =>
        next == MaterialTransactionStatus.Cancelled || (current, next) switch
        {
            (MaterialTransactionStatus.Pending, MaterialTransactionStatus.Accepted) => true,
            (MaterialTransactionStatus.Pending, MaterialTransactionStatus.Rejected) => true,
            (MaterialTransactionStatus.Accepted, MaterialTransactionStatus.Processing) => true,
            (MaterialTransactionStatus.Processing, MaterialTransactionStatus.Ready) => true,
            (MaterialTransactionStatus.Ready, MaterialTransactionStatus.Completed) => true,
            _ => false
        };

    private static MaterialTransactionListDto MapList(MaterialTransaction x) => new()
    {
        Id = x.Id,
        MaterialListingId = x.MaterialListingId,
        ListingTitle = x.MaterialListing?.Title ?? string.Empty,
        Buyer = x.BuyerBusiness?.BusinessName ?? string.Empty,
        Seller = x.SellerBusiness?.BusinessName ?? string.Empty,
        Quantity = x.Quantity,
        Unit = x.Unit,
        TotalAmount = x.TotalAmount,
        Status = (int)x.Status,
        StatusName = x.Status.ToString(),
        DeliveryMethod = (int)(x.Delivery?.Method ?? DeliveryMethod.SelfPickup),
        CreatedAt = x.CreatedAt
    };

    private static MaterialTransactionDetailsDto MapDetails(MaterialTransaction x)
    {
        var list = MapList(x);
        return new MaterialTransactionDetailsDto
        {
            Id = list.Id,
            MaterialListingId = list.MaterialListingId,
            ListingTitle = list.ListingTitle,
            Buyer = list.Buyer,
            Seller = list.Seller,
            Quantity = list.Quantity,
            Unit = list.Unit,
            TotalAmount = list.TotalAmount,
            Status = list.Status,
            StatusName = list.StatusName,
            DeliveryMethod = list.DeliveryMethod,
            CreatedAt = list.CreatedAt,
            BuyerBusinessId = x.BuyerBusinessId,
            SellerBusinessId = x.SellerBusinessId,
            UnitPrice = x.UnitPrice,
            UpdatedAt = x.UpdatedAt,
            Delivery = x.Delivery == null ? null : MapDelivery(x.Delivery),
            StatusHistory = x.StatusHistory.OrderBy(h => h.CreatedAt).Select(MapHistory).ToList()
        };
    }

    internal static DeliveryDto MapDelivery(Delivery x) => new()
    {
        Id = x.Id,
        Method = (int)x.Method,
        MethodName = x.Method.ToString(),
        Location = x.Location,
        CreatedAt = x.CreatedAt,
        UpdatedAt = x.UpdatedAt
    };

    internal static StatusHistoryDto MapHistory(MaterialTransactionStatusHistory x) => new()
    {
        Status = (int)x.Status,
        StatusName = x.Status.ToString(),
        ChangedByBusinessId = x.ChangedByBusinessId,
        ChangedByBusinessName = x.ChangedByBusiness?.BusinessName,
        Note = x.Note,
        CreatedAt = x.CreatedAt
    };

    private static string? CleanLocation(string? value) => string.IsNullOrWhiteSpace(value) ? null : value.Trim();
}
