using EcoLoop.Api.Data;
using EcoLoop.Api.DTOs;
using EcoLoop.Api.Models;
using EcoLoop.Api.Services.Interfaces;
using Microsoft.EntityFrameworkCore;
using System.Data;

namespace EcoLoop.Api.Services;

public class ProductOrderService : IProductOrderService
{
    private readonly EcoLoopDbContext _db;

    public ProductOrderService(EcoLoopDbContext db) => _db = db;

    public async Task<(ProductOrderDetailsDto? Data, string? Error)> CreateAsync(CreateProductOrderRequest request)
    {
        var deliveryError = TransactionRules.ValidateDelivery(request.Delivery);
        if (deliveryError != null) return (null, deliveryError);
        if (request.Items == null || request.Items.Count == 0) return (null, "At least one order item is required.");
        if (request.Items.Any(x => x == null || x.Quantity <= 0)) return (null, "Every item quantity must be greater than zero.");
        if (!Enum.IsDefined(typeof(DeliveryMethod), request.Delivery.Method)) return (null, "Invalid delivery method.");
        if (request.Items.Count > 100 || request.Items.Sum(x => (long)x.Quantity) > int.MaxValue)
            return (null, "Order contains too many items or units.");
        await using var dbTransaction = await _db.Database.BeginTransactionAsync(IsolationLevel.Serializable);
        if (!await _db.Businesses.AnyAsync(x => x.Id == request.BuyerBusinessId)) return (null, "Buyer business was not found.");

        var requestedItems = request.Items
            .GroupBy(x => x.ProductId)
            .Select(x => new { ProductId = x.Key, Quantity = x.Sum(y => y.Quantity) })
            .ToList();
        var productIds = requestedItems.Select(x => x.ProductId).ToList();
        var products = await _db.Products.Include(x => x.Inventory)
            .Where(x => productIds.Contains(x.Id) && x.IsActive).ToListAsync();
        if (products.Count != productIds.Count) return (null, "One or more products were not found or are inactive.");

        var sellerIds = products.Select(x => x.BusinessId).Distinct().ToList();
        if (sellerIds.Count != 1) return (null, "All products in an order must belong to the same seller.");
        var sellerId = sellerIds[0];
        if (sellerId == request.BuyerBusinessId) return (null, "Buyer and seller must be different businesses.");

        foreach (var requested in requestedItems)
        {
            var product = products.Single(x => x.Id == requested.ProductId);
            if (product.Inventory == null || !product.Inventory.IsAvailable || product.Inventory.Quantity < requested.Quantity)
                return (null, $"Insufficient inventory for {product.Name}.");
        }

        if (products.Any(x => x.Price < 0 || x.Price > TransactionRules.MaxAmount || x.Name.Length > 200) ||
            requestedItems.Sum(x => products.Single(p => p.Id == x.ProductId).Price * x.Quantity) > TransactionRules.MaxAmount)
            return (null, "Product price, name or order total exceeds the supported limits.");
        var method = (DeliveryMethod)request.Delivery.Method;
        if (method == DeliveryMethod.SellerDelivery && products.Any(x => !x.SellerDeliveryAvailable))
            return (null, "Seller delivery is not available for every product in this order.");
        if (method == DeliveryMethod.SellerDelivery && string.IsNullOrWhiteSpace(request.Delivery.Location))
            return (null, "A delivery location is required for seller delivery.");

        var now = DateTime.UtcNow;
        var order = new ProductOrder
        {
            BuyerBusinessId = request.BuyerBusinessId,
            SellerBusinessId = sellerId,
            Status = ProductOrderStatus.Placed,
            CreatedAt = now,
            Delivery = new Delivery
            {
                Method = method,
                Location = string.IsNullOrWhiteSpace(request.Delivery.Location) ? null : request.Delivery.Location.Trim(),
                CreatedAt = now
            },
            StatusHistory =
            [
                new ProductOrderStatusHistory
                {
                    Status = ProductOrderStatus.Placed,
                    ChangedByBusinessId = request.BuyerBusinessId,
                    Note = "Order placed",
                    CreatedAt = now
                }
            ]
        };

        foreach (var requested in requestedItems)
        {
            var product = products.Single(x => x.Id == requested.ProductId);
            var lineTotal = decimal.Round(product.Price * requested.Quantity, 2);
            order.Items.Add(new ProductOrderItem
            {
                ProductId = product.Id,
                ProductName = product.Name,
                Quantity = requested.Quantity,
                UnitPrice = product.Price,
                LineTotal = lineTotal,
                CreatedAt = now
            });
            order.TotalAmount += lineTotal;
            product.Inventory!.Quantity -= requested.Quantity;
            product.Inventory.IsAvailable = product.Inventory.Quantity > 0;
        }

        _db.ProductOrders.Add(order);
        await _db.SaveChangesAsync();
        await dbTransaction.CommitAsync();
        return (await GetByIdAsync(order.Id), null);
    }

    public async Task<ProductOrderDetailsDto?> GetByIdAsync(Guid id)
    {
        var item = await BaseQuery().AsNoTracking().FirstOrDefaultAsync(x => x.Id == id);
        return item == null ? null : MapDetails(item);
    }

    public Task<object> GetBuyerHistoryAsync(Guid buyerBusinessId, int page, int pageSize) =>
        GetHistoryAsync(x => x.BuyerBusinessId == buyerBusinessId, page, pageSize);

    public Task<object> GetSellerHistoryAsync(Guid sellerBusinessId, int page, int pageSize) =>
        GetHistoryAsync(x => x.SellerBusinessId == sellerBusinessId, page, pageSize);

    public async Task<(ProductOrderDetailsDto? Data, string? Error)> ChangeStatusAsync(
        Guid id, Guid actingBusinessId, ProductOrderStatus status, string? note)
    {
        if (note?.Length > 500) return (null, "Note must not exceed 500 characters.");
        await using var dbTransaction = await _db.Database.BeginTransactionAsync(IsolationLevel.Serializable);
        var order = await _db.ProductOrders.Include(x => x.Delivery).Include(x => x.Items).FirstOrDefaultAsync(x => x.Id == id);
        if (order == null) return (null, "Product order was not found.");
        if (order.Status is ProductOrderStatus.Completed or ProductOrderStatus.Delivered or ProductOrderStatus.Cancelled)
            return (null, "A terminal order cannot be changed.");
        if (actingBusinessId != order.BuyerBusinessId && actingBusinessId != order.SellerBusinessId)
            return (null, "The acting business is not a party to this order.");
        if (status != ProductOrderStatus.Cancelled && actingBusinessId != order.SellerBusinessId)
            return (null, "Only the seller can progress this order.");
        if (!IsValidTransition(order, status))
            return (null, $"Cannot change order from {order.Status} to {status} for its delivery method.");
        if (status == ProductOrderStatus.Ready && string.IsNullOrWhiteSpace(order.Delivery?.Location))
            return (null, "Set the pickup/delivery address before marking this order ready.");

        if (status == ProductOrderStatus.Cancelled)
        {
            var productIds = order.Items.Select(x => x.ProductId).ToList();
            var inventories = await _db.Inventories.Where(x => productIds.Contains(x.ProductId)).ToDictionaryAsync(x => x.ProductId);
            foreach (var item in order.Items)
            {
                if (!inventories.TryGetValue(item.ProductId, out var inventory))
                    return (null, $"Inventory for {item.ProductName} was not found; cancellation could not safely restore stock.");
                if ((long)inventory.Quantity + item.Quantity > int.MaxValue)
                    return (null, "Restoring stock would exceed the supported quantity.");
                inventory.Quantity += item.Quantity;
                inventory.IsAvailable = inventory.Quantity > 0;
            }
        }

        var now = DateTime.UtcNow;
        order.Status = status;
        order.UpdatedAt = now;
        _db.ProductOrderStatusHistories.Add(new ProductOrderStatusHistory
        {
            ProductOrderId = order.Id,
            Status = status,
            ChangedByBusinessId = actingBusinessId,
            Note = string.IsNullOrWhiteSpace(note) ? null : note.Trim(),
            CreatedAt = now
        });
        await _db.SaveChangesAsync();
        await dbTransaction.CommitAsync();
        return (await GetByIdAsync(id), null);
    }

    public async Task<ProductOrderDetailsDto> UpdateLocationAsync(Guid id, UpdateDeliveryLocationRequest request)
    {
        var order = await _db.ProductOrders.Include(x => x.Delivery).SingleOrDefaultAsync(x => x.Id == id)
            ?? throw new TransactionRuleException(404, "Product order not found.");
        if (order.Delivery == null) throw new TransactionRuleException(404, "Delivery not found.");
        MaterialTransactionService.ValidateLocationEdit(request, order.Delivery, order.BuyerBusinessId, order.SellerBusinessId,
            order.Status is ProductOrderStatus.Placed or ProductOrderStatus.Confirmed or ProductOrderStatus.Processing,
            order.UpdatedAt);
        order.Delivery.Location = request.Location.Trim();
        order.UpdatedAt = order.Delivery.UpdatedAt = DateTime.UtcNow;
        _db.ProductOrderStatusHistories.Add(new()
        {
            ProductOrderId = id, Status = order.Status, ChangedByBusinessId = request.ActingBusinessId,
            Note = "Pickup/delivery location updated.", CreatedAt = order.UpdatedAt.Value
        });
        await _db.SaveChangesAsync();
        return (await GetByIdAsync(id))!;
    }

    private async Task<object> GetHistoryAsync(
        System.Linq.Expressions.Expression<Func<ProductOrder, bool>> predicate,
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

    private IQueryable<ProductOrder> BaseQuery() => _db.ProductOrders
        .Include(x => x.BuyerBusiness)
        .Include(x => x.SellerBusiness)
        .Include(x => x.Items)
        .Include(x => x.Delivery)
        .Include(x => x.StatusHistory).ThenInclude(x => x.ChangedByBusiness);

    private static bool IsValidTransition(ProductOrder order, ProductOrderStatus next)
    {
        if (next == ProductOrderStatus.Cancelled) return true;
        return (order.Status, next) switch
        {
            (ProductOrderStatus.Placed, ProductOrderStatus.Confirmed) => true,
            (ProductOrderStatus.Confirmed, ProductOrderStatus.Processing) => true,
            (ProductOrderStatus.Processing, ProductOrderStatus.Ready) => true,
            (ProductOrderStatus.Ready, ProductOrderStatus.Completed) => order.Delivery?.Method == DeliveryMethod.SelfPickup,
            (ProductOrderStatus.Ready, ProductOrderStatus.Delivered) => order.Delivery?.Method == DeliveryMethod.SellerDelivery,
            _ => false
        };
    }

    private static ProductOrderListDto MapList(ProductOrder x) => new()
    {
        Id = x.Id,
        Buyer = x.BuyerBusiness?.BusinessName ?? string.Empty,
        Seller = x.SellerBusiness?.BusinessName ?? string.Empty,
        ItemCount = x.Items.Sum(i => i.Quantity),
        TotalAmount = x.TotalAmount,
        Status = (int)x.Status,
        StatusName = x.Status.ToString(),
        DeliveryMethod = (int)(x.Delivery?.Method ?? DeliveryMethod.SelfPickup),
        CreatedAt = x.CreatedAt
    };

    private static ProductOrderDetailsDto MapDetails(ProductOrder x)
    {
        var list = MapList(x);
        return new ProductOrderDetailsDto
        {
            Id = list.Id,
            Buyer = list.Buyer,
            Seller = list.Seller,
            ItemCount = list.ItemCount,
            TotalAmount = list.TotalAmount,
            Status = list.Status,
            StatusName = list.StatusName,
            DeliveryMethod = list.DeliveryMethod,
            CreatedAt = list.CreatedAt,
            BuyerBusinessId = x.BuyerBusinessId,
            SellerBusinessId = x.SellerBusinessId,
            UpdatedAt = x.UpdatedAt,
            Items = x.Items.Select(i => new ProductOrderItemDto
            {
                ProductId = i.ProductId,
                ProductName = i.ProductName,
                Quantity = i.Quantity,
                UnitPrice = i.UnitPrice,
                LineTotal = i.LineTotal
            }).ToList(),
            Delivery = x.Delivery == null ? null : MaterialTransactionService.MapDelivery(x.Delivery),
            StatusHistory = x.StatusHistory.OrderBy(h => h.CreatedAt).Select(h => new StatusHistoryDto
            {
                Status = (int)h.Status,
                StatusName = h.Status.ToString(),
                ChangedByBusinessId = h.ChangedByBusinessId,
                ChangedByBusinessName = h.ChangedByBusiness?.BusinessName,
                Note = h.Note,
                CreatedAt = h.CreatedAt
            }).ToList()
        };
    }
}
