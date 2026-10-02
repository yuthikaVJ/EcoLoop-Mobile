using EcoLoop.Api.Data;
using EcoLoop.Api.DTOs;
using EcoLoop.Api.Models;
using EcoLoop.Api.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace EcoLoop.Api.Services;

// Seller Delivery: EcoLoop has no rider fleet, so the seller drives. The seller starts a
// delivery once the transaction/order is Ready, shares their position while on the way,
// and marks it delivered, which completes the parent through its normal status rules.
public class DeliveryTrackingService(
    EcoLoopDbContext db,
    IMaterialTransactionService materials,
    IProductOrderService products)
{
    public async Task<List<SellerDeliveryDto>> GetForSellerAsync(Guid sellerBusinessId, bool includeFinished)
    {
        var materialJobs = await db.Deliveries.AsNoTracking()
            .Where(d => d.Method == DeliveryMethod.SellerDelivery && d.MaterialTransaction != null
                && d.MaterialTransaction.SellerBusinessId == sellerBusinessId
                && d.MaterialTransaction.Status != MaterialTransactionStatus.Rejected
                && d.MaterialTransaction.Status != MaterialTransactionStatus.Cancelled
                // Active = still to deliver; the buyer may also have confirmed receipt first.
                && (includeFinished || (d.Status != DeliveryStatus.Delivered
                    && d.MaterialTransaction.Status != MaterialTransactionStatus.Completed)))
            .Select(d => new SellerDeliveryDto
            {
                Id = d.Id,
                Kind = "material",
                ParentId = d.MaterialTransaction!.Id,
                Title = d.MaterialTransaction.MaterialListing != null ? d.MaterialTransaction.MaterialListing.Title : "Material",
                Buyer = d.MaterialTransaction.BuyerBusiness != null ? d.MaterialTransaction.BuyerBusiness.BusinessName : string.Empty,
                Destination = d.Location,
                TotalAmount = d.MaterialTransaction.TotalAmount,
                ParentStatus = (int)d.MaterialTransaction.Status,
                ParentStatusName = d.MaterialTransaction.Status.ToString(),
                Status = (int)d.Status,
                StatusName = d.Status.ToString(),
                CurrentLatitude = d.CurrentLatitude,
                CurrentLongitude = d.CurrentLongitude,
                LocationUpdatedAt = d.LocationUpdatedAt,
                CreatedAt = d.CreatedAt
            })
            .ToListAsync();

        var productJobs = await db.Deliveries.AsNoTracking()
            .Where(d => d.Method == DeliveryMethod.SellerDelivery && d.ProductOrder != null
                && d.ProductOrder.SellerBusinessId == sellerBusinessId
                && d.ProductOrder.Status != ProductOrderStatus.Cancelled
                && (includeFinished || (d.Status != DeliveryStatus.Delivered
                    && d.ProductOrder.Status != ProductOrderStatus.Delivered
                    && d.ProductOrder.Status != ProductOrderStatus.Completed)))
            .Select(d => new SellerDeliveryDto
            {
                Id = d.Id,
                Kind = "product",
                ParentId = d.ProductOrder!.Id,
                Title = d.ProductOrder.Items.OrderBy(i => i.CreatedAt).Select(i => i.ProductName).FirstOrDefault() ?? "Product order",
                Buyer = d.ProductOrder.BuyerBusiness != null ? d.ProductOrder.BuyerBusiness.BusinessName : string.Empty,
                Destination = d.Location,
                TotalAmount = d.ProductOrder.TotalAmount,
                ParentStatus = (int)d.ProductOrder.Status,
                ParentStatusName = d.ProductOrder.Status.ToString(),
                Status = (int)d.Status,
                StatusName = d.Status.ToString(),
                CurrentLatitude = d.CurrentLatitude,
                CurrentLongitude = d.CurrentLongitude,
                LocationUpdatedAt = d.LocationUpdatedAt,
                CreatedAt = d.CreatedAt
            })
            .ToListAsync();

        // Active jobs first (on the way, then not started), newest first within each group.
        return materialJobs.Concat(productJobs)
            .OrderBy(j => j.Status switch { (int)DeliveryStatus.OnTheWay => 0, (int)DeliveryStatus.NotStarted => 1, _ => 2 })
            .ThenByDescending(j => j.CreatedAt)
            .ToList();
    }

    public async Task<SellerDeliveryDto> StartAsync(Guid deliveryId, Guid sellerBusinessId)
    {
        var delivery = await LoadForSellerAsync(deliveryId, sellerBusinessId);
        if (delivery.Status != DeliveryStatus.NotStarted)
            throw new TransactionRuleException(409, "This delivery has already been started.");
        if (!ParentIsReady(delivery))
            throw new TransactionRuleException(409, "Mark the transaction/order as Ready before starting the delivery.");
        delivery.Status = DeliveryStatus.OnTheWay;
        delivery.UpdatedAt = DateTime.UtcNow;
        await db.SaveChangesAsync();
        return await GetOneAsync(deliveryId, sellerBusinessId);
    }

    public async Task<SellerDeliveryDto> UpdatePositionAsync(Guid deliveryId, Guid sellerBusinessId, DeliveryPositionRequest position)
    {
        if (!double.IsFinite(position.Latitude) || !double.IsFinite(position.Longitude)
            || Math.Abs(position.Latitude) > 90 || Math.Abs(position.Longitude) > 180)
            throw new TransactionRuleException(400, "Latitude must be between -90 and 90 and longitude between -180 and 180.");
        var delivery = await LoadForSellerAsync(deliveryId, sellerBusinessId);
        if (delivery.Status != DeliveryStatus.OnTheWay)
            throw new TransactionRuleException(409, "You can only share your location while the delivery is on the way.");
        delivery.CurrentLatitude = position.Latitude;
        delivery.CurrentLongitude = position.Longitude;
        delivery.LocationUpdatedAt = DateTime.UtcNow;
        await db.SaveChangesAsync();
        return await GetOneAsync(deliveryId, sellerBusinessId);
    }

    public async Task<SellerDeliveryDto> MarkDeliveredAsync(Guid deliveryId, Guid sellerBusinessId)
    {
        var delivery = await LoadForSellerAsync(deliveryId, sellerBusinessId);
        if (delivery.Status != DeliveryStatus.OnTheWay)
            throw new TransactionRuleException(409, "Start the delivery before marking it delivered.");

        // Set the delivery first: the parent service's SaveChanges then persists both together,
        // and if its status rules reject the change nothing is saved.
        delivery.Status = DeliveryStatus.Delivered;
        delivery.UpdatedAt = DateTime.UtcNow;
        var error = delivery.MaterialTransactionId is { } transactionId
            ? (await materials.ChangeStatusAsync(transactionId, sellerBusinessId, MaterialTransactionStatus.Completed, "Delivered by seller")).Error
            : (await products.ChangeStatusAsync(delivery.ProductOrderId!.Value, sellerBusinessId, ProductOrderStatus.Delivered, "Delivered by seller")).Error;
        if (error != null)
        {
            db.Entry(delivery).State = EntityState.Unchanged;
            throw new TransactionRuleException(409, error);
        }
        return await GetOneAsync(deliveryId, sellerBusinessId);
    }

    private async Task<Delivery> LoadForSellerAsync(Guid deliveryId, Guid sellerBusinessId)
    {
        var delivery = await db.Deliveries
            .Include(d => d.MaterialTransaction)
            .Include(d => d.ProductOrder)
            .SingleOrDefaultAsync(d => d.Id == deliveryId)
            ?? throw new TransactionRuleException(404, "Delivery not found.");
        var seller = delivery.MaterialTransaction?.SellerBusinessId ?? delivery.ProductOrder?.SellerBusinessId;
        if (seller != sellerBusinessId)
            throw new TransactionRuleException(403, "Only the seller can manage this delivery.");
        if (delivery.Method != DeliveryMethod.SellerDelivery)
            throw new TransactionRuleException(409, "This is a self-pickup; there is nothing to deliver.");
        return delivery;
    }

    private static bool ParentIsReady(Delivery delivery) =>
        delivery.MaterialTransaction?.Status == MaterialTransactionStatus.Ready
        || delivery.ProductOrder?.Status == ProductOrderStatus.Ready;

    private async Task<SellerDeliveryDto> GetOneAsync(Guid deliveryId, Guid sellerBusinessId) =>
        (await GetForSellerAsync(sellerBusinessId, includeFinished: true)).Single(j => j.Id == deliveryId);
}
