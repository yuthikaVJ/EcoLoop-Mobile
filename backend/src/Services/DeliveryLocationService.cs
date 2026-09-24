using EcoLoop.Api.Data;
using EcoLoop.Api.DTOs;
using EcoLoop.Api.Models;
using Microsoft.EntityFrameworkCore;

namespace EcoLoop.Api.Services;

public class DeliveryLocationService(EcoLoopDbContext db)
{
    public async Task<List<DeliveryLocationDto>> ListAsync(Guid businessId) =>
        (await db.DeliveryLocations.AsNoTracking().Where(x => x.BusinessId == businessId)
            .OrderBy(x => x.Label).ToListAsync()).Select(Map).ToList();

    public async Task<DeliveryLocationDto> GetAsync(Guid id, Guid businessId) => Map(await FindAsync(id, businessId));

    public async Task<DeliveryLocationDto> SaveAsync(Guid? id, SaveDeliveryLocationRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.Label) || request.Label.Length > 80 ||
            string.IsNullOrWhiteSpace(request.Address) || request.Address.Length > 500)
            throw new TransactionRuleException(400, "Label (1-80 characters) and address (1-500 characters) are required.");
        if (request.Latitude.HasValue != request.Longitude.HasValue ||
            request.Latitude is double lat && (!double.IsFinite(lat) || lat < -90 || lat > 90) ||
            request.Longitude is double lng && (!double.IsFinite(lng) || lng < -180 || lng > 180))
            throw new TransactionRuleException(400, "Provide both valid latitude and longitude, or neither.");
        if (!await db.Businesses.AnyAsync(x => x.Id == request.BusinessId))
            throw new TransactionRuleException(400, "Business not found.");
        var item = id.HasValue ? await FindAsync(id.Value, request.BusinessId) : new DeliveryLocation { BusinessId = request.BusinessId };
        if (id.HasValue && request.ExpectedUpdatedAt != item.UpdatedAt)
            throw new TransactionRuleException(409, "Location changed. Reload it before editing.");
        item.Label = request.Label.Trim();
        item.Address = request.Address.Trim();
        item.Latitude = request.Latitude;
        item.Longitude = request.Longitude;
        item.UpdatedAt = new DateTime(DateTime.UtcNow.Ticks / 10 * 10, DateTimeKind.Utc);
        if (!id.HasValue) db.DeliveryLocations.Add(item);
        await db.SaveChangesAsync();
        return Map(item);
    }

    public async Task DeleteAsync(Guid id, Guid businessId)
    {
        db.DeliveryLocations.Remove(await FindAsync(id, businessId));
        await db.SaveChangesAsync();
    }

    private async Task<DeliveryLocation> FindAsync(Guid id, Guid businessId) =>
        await db.DeliveryLocations.SingleOrDefaultAsync(x => x.Id == id && x.BusinessId == businessId)
            ?? throw new TransactionRuleException(404, "Saved location not found.");

    private static DeliveryLocationDto Map(DeliveryLocation x) =>
        new(x.Id, x.Label, x.Address, x.Latitude, x.Longitude, x.CreatedAt, x.UpdatedAt);
}
