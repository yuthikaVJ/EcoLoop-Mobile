using EcoLoop.Api.Data;
using EcoLoop.Api.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace EcoLoop.Api.Controllers;

[ApiController]
[Route("api/products")]
public class ProductsController : ControllerBase
{
    private readonly EcoLoopDbContext _db;

    public ProductsController(EcoLoopDbContext db)
    {
        _db = db;
    }

    [HttpGet]
    public async Task<IActionResult> GetProducts(
        string? search,
        Guid? categoryId,
        string? materialType,
        decimal? minPrice,
        decimal? maxPrice,
        string sort = "newest",
        int page = 1,
        int pageSize = 20)
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
            query = query.Where(product =>
                product.Name.ToLower().Contains(search.ToLower()) ||
                product.Description.ToLower().Contains(search.ToLower()));
        }

        if (categoryId.HasValue)
            query = query.Where(product => product.CategoryId == categoryId);

        if (!string.IsNullOrWhiteSpace(materialType))
            query = query.Where(product => product.MaterialType == materialType);

        if (minPrice.HasValue)
            query = query.Where(product => product.Price >= minPrice);

        if (maxPrice.HasValue)
            query = query.Where(product => product.Price <= maxPrice);

        query = sort switch
        {
            "price_asc" => query.OrderBy(product => product.Price),
            "price_desc" => query.OrderByDescending(product => product.Price),
            _ => query.OrderByDescending(product => product.CreatedAt)
        };

        var totalItems = await query.CountAsync();

        var items = await query
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(product => new
            {
                product.Id,
                product.Name,
                product.Description,
                product.MaterialType,
                product.Price,
                Category = product.Category!.Name,
                AvailableQuantity = product.Inventory == null
                    ? 0
                    : product.Inventory.AvailableQuantity,
                Seller = product.Business!.BusinessName,
                SellerIsVerified = product.Business.IsVerified,
                PrimaryImageUrl = product.Images
                    .Where(image => image.IsPrimary)
                    .Select(image => image.ImageUrl)
                    .FirstOrDefault()
            })
            .ToListAsync();

        return Ok(new
        {
            items,
            page,
            pageSize,
            totalItems,
            totalPages = (int)Math.Ceiling((double)totalItems / pageSize)
        });
    }

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> GetProduct(Guid id)
    {
        var product = await _db.Products
            .AsNoTracking()
            .Include(product => product.Category)
            .Include(product => product.Business)
            .Include(product => product.Inventory)
            .Include(product => product.Images)
            .FirstOrDefaultAsync(product => product.Id == id);

        return product == null ? NotFound() : Ok(product);
    }

    [HttpPost]
    public async Task<IActionResult> CreateProduct(Product product)
    {
        product.Id = Guid.NewGuid();
        product.CreatedAt = DateTime.UtcNow;
        product.IsActive = true;

        _db.Products.Add(product);
        await _db.SaveChangesAsync();

        return CreatedAtAction(
            nameof(GetProduct),
            new { id = product.Id },
            product);
    }

    [HttpPut("{id:guid}")]
    public async Task<IActionResult> UpdateProduct(
        Guid id,
        Product request)
    {
        var product = await _db.Products.FindAsync(id);

        if (product == null)
            return NotFound();

        product.Name = request.Name;
        product.Description = request.Description;
        product.MaterialType = request.MaterialType;
        product.Price = request.Price;
        product.CategoryId = request.CategoryId;
        product.BusinessId = request.BusinessId;

        await _db.SaveChangesAsync();

        return Ok(product);
    }

    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> DisableProduct(Guid id)
    {
        var product = await _db.Products.FindAsync(id);

        if (product == null)
            return NotFound();

        product.IsActive = false;
        await _db.SaveChangesAsync();

        return NoContent();
    }
}