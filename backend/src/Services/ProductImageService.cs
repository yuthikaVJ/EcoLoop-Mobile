using EcoLoop.Api.Data;
using EcoLoop.Api.DTOs;
using EcoLoop.Api.Models;
using EcoLoop.Api.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace EcoLoop.Api.Services;

public class ProductImageService : IProductImageService
{
    private readonly EcoLoopDbContext _db;

    public ProductImageService(EcoLoopDbContext db)
    {
        _db = db;
    }

    public async Task<List<ProductImage>> GetByProductIdAsync(
        Guid productId)
    {
        return await _db.ProductImages
            .AsNoTracking()
            .Where(image => image.ProductId == productId)
            .OrderBy(image => image.DisplayOrder)
            .ToListAsync();
    }

    public async Task<ProductImage?> CreateAsync(
        Guid productId,
        CreateProductImageRequest request)
    {
        var productExists = await _db.Products
            .AnyAsync(product => product.Id == productId);

        if (!productExists)
            return null;

        if (request.IsPrimary)
        {
            var existingImages = await _db.ProductImages
                .Where(image => image.ProductId == productId)
                .ToListAsync();

            foreach (var image in existingImages)
                image.IsPrimary = false;
        }

        var productImage = new ProductImage
        {
            ProductId = productId,
            ImageUrl = request.ImageUrl,
            IsPrimary = request.IsPrimary,
            DisplayOrder = request.DisplayOrder
        };

        _db.ProductImages.Add(productImage);
        await _db.SaveChangesAsync();

        return productImage;
    }

    public async Task<ProductImage?> UpdateAsync(
        Guid productId,
        Guid imageId,
        UpdateProductImageRequest request)
    {
        var image = await _db.ProductImages
            .FirstOrDefaultAsync(image =>
                image.Id == imageId &&
                image.ProductId == productId);

        if (image == null)
            return null;

        if (request.IsPrimary)
        {
            var existingImages = await _db.ProductImages
                .Where(existing =>
                    existing.ProductId == productId &&
                    existing.Id != imageId)
                .ToListAsync();

            foreach (var existingImage in existingImages)
                existingImage.IsPrimary = false;
        }

        image.ImageUrl = request.ImageUrl;
        image.IsPrimary = request.IsPrimary;
        image.DisplayOrder = request.DisplayOrder;

        await _db.SaveChangesAsync();

        return image;
    }

    public async Task<bool> DeleteAsync(
        Guid productId,
        Guid imageId)
    {
        var image = await _db.ProductImages
            .FirstOrDefaultAsync(image =>
                image.Id == imageId &&
                image.ProductId == productId);

        if (image == null)
            return false;

        _db.ProductImages.Remove(image);
        await _db.SaveChangesAsync();

        return true;
    }
}