using EcoLoop.Api.Data;
using EcoLoop.Api.DTOs;
using EcoLoop.Api.Models;
using EcoLoop.Api.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace EcoLoop.Api.Services;

public class ProductService : IProductService
{
    private readonly EcoLoopDbContext _db;

    public ProductService(EcoLoopDbContext db)
    {
        _db = db;
    }

    public async Task<object> GetProductsAsync(
        string? search,
        Guid? categoryId,
        string? materialType,
        decimal? minPrice,
        decimal? maxPrice,
        string sort,
        int page,
        int pageSize)
    {
        page = Math.Max(page, 1);
        pageSize = Math.Clamp(pageSize, 1, 100);

        var query = _db.Products
            .AsNoTracking()
            .Include(product => product.Category)
            .Include(product => product.Business)
            .Include(product => product.Inventory)
            .Include(product => product.Images)
            .Where(product => product.IsActive);

        if (!string.IsNullOrWhiteSpace(search))
        {
            var searchText = search.Trim().ToLower();

            query = query.Where(product =>
                product.Name.ToLower().Contains(searchText) ||
                product.Description.ToLower().Contains(searchText) ||
                product.MaterialType.ToLower().Contains(searchText));
        }

        if (categoryId.HasValue)
            query = query.Where(product => product.CategoryId == categoryId.Value);

        if (!string.IsNullOrWhiteSpace(materialType))
            query = query.Where(product => product.MaterialType == materialType);

        if (minPrice.HasValue)
            query = query.Where(product => product.Price >= minPrice.Value);

        if (maxPrice.HasValue)
            query = query.Where(product => product.Price <= maxPrice.Value);

        query = sort.ToLower() switch
        {
            "price_asc" => query.OrderBy(product => product.Price),
            "price_desc" => query.OrderByDescending(product => product.Price),
            "name_asc" => query.OrderBy(product => product.Name),
            _ => query.OrderByDescending(product => product.CreatedAt)
        };

        var totalItems = await query.CountAsync();

        var items = await query
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(product => new ProductListDto
            {
                Id = product.Id,
                Name = product.Name,
                Description = product.Description,
                MaterialType = product.MaterialType,
                Price = product.Price,
                Category = product.Category == null
                    ? null
                    : product.Category.Name,
                Seller = product.Business == null
                    ? null
                    : product.Business.BusinessName,
                SellerIsVerified = product.Business != null &&
                                    product.Business.IsVerified,
                AvailableQuantity = product.Inventory == null
                    ? 0
                    : product.Inventory.AvailableQuantity,
                PrimaryImageUrl = product.Images
                    .Where(image => image.IsPrimary)
                    .Select(image => image.ImageUrl)
                    .FirstOrDefault()
            })
            .ToListAsync();

        return new
        {
            items,
            page,
            pageSize,
            totalItems,
            totalPages = (int)Math.Ceiling(
                (double)totalItems / pageSize)
        };
    }

    public async Task<ProductDetailsDto?> GetByIdAsync(Guid id)
    {
        return await _db.Products
            .AsNoTracking()
            .Where(product => product.Id == id && product.IsActive)
            .Select(product => new ProductDetailsDto
            {
                Id = product.Id,
                Name = product.Name,
                Description = product.Description,
                MaterialType = product.MaterialType,
                Price = product.Price,
                Category = product.Category == null
                    ? null
                    : product.Category.Name,
                Seller = product.Business == null
                    ? null
                    : product.Business.BusinessName,
                SellerIsVerified = product.Business != null &&
                                    product.Business.IsVerified,
                AvailableQuantity = product.Inventory == null
                    ? 0
                    : product.Inventory.AvailableQuantity,
                Images = product.Images
                    .OrderBy(image => image.DisplayOrder)
                    .Select(image => image.ImageUrl)
                    .ToList()
            })
            .FirstOrDefaultAsync();
    }

    public async Task<ProductDetailsDto> CreateAsync(
        CreateProductRequest request)
    {
        var product = new Product
        {
            CategoryId = request.CategoryId,
            BusinessId = request.BusinessId,
            Name = request.Name,
            Description = request.Description,
            MaterialType = request.MaterialType,
            Price = request.Price,
            IsActive = true,
            CreatedAt = DateTime.UtcNow
        };

        _db.Products.Add(product);
        await _db.SaveChangesAsync();

        return (await GetByIdAsync(product.Id))!;
    }

    public async Task<ProductDetailsDto?> UpdateAsync(
        Guid id,
        UpdateProductRequest request)
    {
        var product = await _db.Products
            .FirstOrDefaultAsync(product => product.Id == id);

        if (product == null)
            return null;

        product.CategoryId = request.CategoryId;
        product.Name = request.Name;
        product.Description = request.Description;
        product.MaterialType = request.MaterialType;
        product.Price = request.Price;

        await _db.SaveChangesAsync();

        return await GetByIdAsync(id);
    }

    public async Task<bool> DisableAsync(Guid id)
    {
        var product = await _db.Products
            .FirstOrDefaultAsync(product => product.Id == id);

        if (product == null)
            return false;

        product.IsActive = false;
        await _db.SaveChangesAsync();

        return true;
    }
}