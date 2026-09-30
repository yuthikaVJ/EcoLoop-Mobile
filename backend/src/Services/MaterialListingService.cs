using EcoLoop.Api.Data;
using EcoLoop.Api.DTOs;
using EcoLoop.Api.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace EcoLoop.Api.Services;

public class MaterialListingService : IMaterialListingService
{
    private readonly EcoLoopDbContext _db;

    public MaterialListingService(EcoLoopDbContext db)
    {
        _db = db;
    }

    public async Task<object> GetAllAsync(
        string? search,
        string? category,
        int? type,
        int page,
        int pageSize)
    {
        page = Math.Max(page, 1);
        pageSize = Math.Clamp(pageSize, 1, 100);

        // Build the base query
        var query = _db.MaterialListings
            .AsNoTracking()
            .Include(listing => listing.Business)
            .Where(listing => (int)listing.Status == 0); // Status 0 = Active

        // Apply filters
        if (!string.IsNullOrWhiteSpace(search))
        {
            var searchText = search.Trim().ToLower();
            query = query.Where(listing =>
                listing.Title.ToLower().Contains(searchText) ||
                listing.Description.ToLower().Contains(searchText));
        }

        if (!string.IsNullOrWhiteSpace(category))
            query = query.Where(listing => listing.Category == category);

        if (type.HasValue)
            query = query.Where(listing => (int)listing.Type == type.Value);

        // Order by newest first
        query = query.OrderByDescending(listing => listing.CreatedAt);

        var totalItems = await query.CountAsync();

        // Project to DTO
        var items = await query
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(listing => new MaterialListingListDto
            {
                Id = listing.Id,
                Title = listing.Title,
                Category = listing.Category,
                Quantity = listing.Quantity,
                Location = listing.Location,
                Price = listing.Price,
                PriceUnit = listing.PriceUnit,
                Seller = listing.Business != null ? listing.Business.BusinessName : null,
                SellerIsVerified = listing.Business != null && listing.Business.IsVerified,
                Type = (int)listing.Type,
                Status = (int)listing.Status,
                CreatedAt = listing.CreatedAt,
                ImageUrl = listing.ImageUrl
            })
            .ToListAsync();

        return new
        {
            items,
            page,
            pageSize,
            totalItems,
            totalPages = (int)Math.Ceiling((double)totalItems / pageSize)
        };
    }

    public async Task<MaterialListingDetailsDto?> GetByIdAsync(Guid id)
    {
        return await _db.MaterialListings
            .AsNoTracking()
            .Include(listing => listing.Business)
            .Where(listing => listing.Id == id && (int)listing.Status == 0)
            .Select(listing => new MaterialListingDetailsDto
            {
                Id = listing.Id,
                BusinessId = listing.BusinessId,
                Title = listing.Title,
                Category = listing.Category,
                Description = listing.Description,
                Quantity = listing.Quantity,
                Unit = listing.Unit,
                Location = listing.Location,
                Price = listing.Price,
                PriceUnit = listing.PriceUnit,
                DeliveryMethod = listing.DeliveryMethod,
                Seller = listing.Business != null ? listing.Business.BusinessName : null,
                SellerIsVerified = listing.Business != null && listing.Business.IsVerified,
                Type = (int)listing.Type,
                Status = (int)listing.Status,
                CreatedAt = listing.CreatedAt,
                ImageUrl = listing.ImageUrl
            })
            .FirstOrDefaultAsync();
    }

    public async Task<MaterialListingDetailsDto> CreateAsync(CreateMaterialListingRequest request)
    {
        var listing = new EcoLoop.Api.Models.MaterialListing
        {
            BusinessId = request.BusinessId,
            Title = request.Title,
            Category = request.Category,
            Description = request.Description,
            Quantity = request.Quantity,
            Unit = request.Unit,
            Location = request.Location,
            Price = request.Price,
            PriceUnit = request.PriceUnit,
            DeliveryMethod = request.DeliveryMethod,
            Type = (EcoLoop.Api.Models.ListingType)request.Type,
            Status = EcoLoop.Api.Models.ListingStatus.Active,
            CreatedAt = DateTime.UtcNow,
            ImageUrl = request.ImageUrl
        };

        _db.MaterialListings.Add(listing);
        await _db.SaveChangesAsync();

        return (await GetByIdAsync(listing.Id))!;
    }

    public async Task<MaterialListingDetailsDto?> UpdateAsync(Guid id, UpdateMaterialListingRequest request)
    {
        var listing = await _db.MaterialListings
            .FirstOrDefaultAsync(l => l.Id == id && (int)l.Status == 0);

        if (listing == null)
            return null;

        listing.Title = request.Title;
        listing.Category = request.Category;
        listing.Description = request.Description;
        listing.Quantity = request.Quantity;
        listing.Unit = request.Unit;
        listing.Location = request.Location;
        listing.Price = request.Price;
        listing.PriceUnit = request.PriceUnit;
        listing.DeliveryMethod = request.DeliveryMethod;
        listing.UpdatedAt = DateTime.UtcNow;

        await _db.SaveChangesAsync();

        return await GetByIdAsync(id);
    }

    public async Task<bool> ChangeStatusAsync(Guid id, int newStatus)
    {
        var listing = await _db.MaterialListings
            .FirstOrDefaultAsync(l => l.Id == id);

        if (listing == null)
            return false;

        // Ensure the status is valid (0=Active, 1=Completed, 2=Deleted)
        if (!Enum.IsDefined(typeof(EcoLoop.Api.Models.ListingStatus), newStatus))
            return false;

        listing.Status = (EcoLoop.Api.Models.ListingStatus)newStatus;
        listing.UpdatedAt = DateTime.UtcNow;

        await _db.SaveChangesAsync();

        return true;
    }
}
