using EcoLoop.Api.Data;
using EcoLoop.Api.DTOs;
using EcoLoop.Api.Services.Interfaces;
using Microsoft.EntityFrameworkCore;
using System.Linq.Expressions;

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
        int pageSize,
        Guid? businessId = null,
        int status = 0)
    {
        page = Math.Max(page, 1);
        pageSize = Math.Clamp(pageSize, 1, 100);

        // Build the base query
        var query = _db.MaterialListings
            .AsNoTracking()
            .Include(listing => listing.Business)
            .Include(listing => listing.PostedAsBusiness)
            .Where(listing => (int)listing.Status == status);

        if (businessId.HasValue)
            query = query.Where(listing => listing.BusinessId == businessId.Value);

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
            .Select(ToListDto)
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

    // Active and completed listings owned by one business (for "My Listings")
    public async Task<List<MaterialListingListDto>> GetByBusinessAsync(Guid businessId)
    {
        return await _db.MaterialListings
            .AsNoTracking()
            .Include(listing => listing.Business)
            .Include(listing => listing.PostedAsBusiness)
            .Where(listing => listing.BusinessId == businessId &&
                              listing.Status != EcoLoop.Api.Models.ListingStatus.Deleted)
            .OrderByDescending(listing => listing.CreatedAt)
            .Select(ToListDto)
            .ToListAsync();
    }

    private static readonly Expression<Func<EcoLoop.Api.Models.MaterialListing, MaterialListingListDto>> ToListDto =
        listing => new MaterialListingListDto
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
            PostedAsBusinessId = listing.PostedAsBusinessId,
            Seller = listing.PostedAsBusiness != null
                ? listing.PostedAsBusiness.BusinessName
                : listing.Business != null ? listing.Business.BusinessName : null,
            SellerLogoUrl = listing.PostedAsBusiness != null
                ? listing.PostedAsBusiness.LogoUrl
                : listing.Business != null ? listing.Business.LogoUrl : null,
            SellerIsVerified = listing.PostedAsBusiness != null
                ? listing.PostedAsBusiness.IsVerified
                : listing.Business != null && listing.Business.IsVerified,
            Type = (int)listing.Type,
            Status = (int)listing.Status,
            CreatedAt = listing.CreatedAt,
            ImageUrl = listing.ImageUrl,
            ImageUrls = listing.ImageUrls,
            Availability = listing.Availability,
            Condition = listing.Condition,
            SellerDeliveryAvailable = listing.SellerDeliveryAvailable
        };

    public async Task<MaterialListingDetailsDto?> GetByIdAsync(Guid id)
    {
        return await _db.MaterialListings
            .AsNoTracking()
            .Include(listing => listing.Business)
            .Include(listing => listing.PostedAsBusiness)
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
                PostedAsBusinessId = listing.PostedAsBusinessId,
                Seller = listing.PostedAsBusiness != null
                    ? listing.PostedAsBusiness.BusinessName
                    : listing.Business != null ? listing.Business.BusinessName : null,
                SellerLogoUrl = listing.PostedAsBusiness != null
                    ? listing.PostedAsBusiness.LogoUrl
                    : listing.Business != null ? listing.Business.LogoUrl : null,
                SellerIsVerified = listing.PostedAsBusiness != null
                    ? listing.PostedAsBusiness.IsVerified
                    : listing.Business != null && listing.Business.IsVerified,
                Type = (int)listing.Type,
                Status = (int)listing.Status,
                CreatedAt = listing.CreatedAt,
                ImageUrl = listing.ImageUrl,
                ImageUrls = listing.ImageUrls,
                Availability = listing.Availability,
                Condition = listing.Condition,
                SellerDeliveryAvailable = listing.SellerDeliveryAvailable
            })
            .FirstOrDefaultAsync();
    }

    public async Task<MaterialListingDetailsDto> CreateAsync(CreateMaterialListingRequest request)
    {
        var listing = new EcoLoop.Api.Models.MaterialListing
        {
            BusinessId = request.BusinessId,
            PostedAsBusinessId = request.PostedAsBusinessId,
            Availability = Trimmed(request.Availability, 50),
            Condition = Trimmed(request.Condition, 100),
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
            ImageUrl = request.ImageUrl,
            ImageUrls = request.ImageUrls,
            SellerDeliveryAvailable = request.SellerDeliveryAvailable
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
        listing.SellerDeliveryAvailable = request.SellerDeliveryAvailable;
        if (request.Availability != null) listing.Availability = Trimmed(request.Availability, 50);
        if (request.Condition != null) listing.Condition = Trimmed(request.Condition, 100);
        if (request.KeepImageUrls != null)
        {
            // Only photos already on this listing can be kept (no arbitrary URLs).
            // Compare paths: clients send full URLs with their own server address.
            var current = CurrentPhotos(listing)
                .GroupBy(MediaPaths.Normalize)
                .ToDictionary(g => g.Key, g => g.First());
            var kept = request.KeepImageUrls
                .Select(MediaPaths.Normalize)
                .Where(current.ContainsKey)
                .Distinct()
                .Select(path => current[path])
                .ToList();
            listing.ImageUrls = kept;
            listing.ImageUrl = kept.FirstOrDefault();
        }
        listing.UpdatedAt = DateTime.UtcNow;

        await _db.SaveChangesAsync();

        return await GetByIdAsync(id);
    }

    public async Task<int?> ImageCountAsync(Guid id)
    {
        var listing = await _db.MaterialListings.AsNoTracking().FirstOrDefaultAsync(l => l.Id == id && (int)l.Status == 0);
        return listing == null ? null : CurrentPhotos(listing).Count;
    }

    public async Task<MaterialListingDetailsDto?> AddImagesAsync(Guid id, List<string> imageUrls)
    {
        var listing = await _db.MaterialListings.FirstOrDefaultAsync(l => l.Id == id && (int)l.Status == 0);
        if (listing == null)
            return null;

        listing.ImageUrls = CurrentPhotos(listing).Concat(imageUrls).ToList();
        listing.ImageUrl = listing.ImageUrls.FirstOrDefault();
        listing.UpdatedAt = DateTime.UtcNow;
        await _db.SaveChangesAsync();
        return await GetByIdAsync(id);
    }

    // Listings created before multiple photos only have ImageUrl.
    private static List<string> CurrentPhotos(EcoLoop.Api.Models.MaterialListing listing) =>
        listing.ImageUrls.Count > 0 ? [.. listing.ImageUrls]
        : string.IsNullOrEmpty(listing.ImageUrl) ? [] : [listing.ImageUrl];

    public async Task<Guid?> GetOwnerIdAsync(Guid id) =>
        await _db.MaterialListings.Where(l => l.Id == id).Select(l => (Guid?)l.BusinessId).FirstOrDefaultAsync();

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

    private static string? Trimmed(string? text, int max)
    {
        var value = text?.Trim();
        return string.IsNullOrEmpty(value) ? null : value.Length <= max ? value : value[..max];
    }
}
