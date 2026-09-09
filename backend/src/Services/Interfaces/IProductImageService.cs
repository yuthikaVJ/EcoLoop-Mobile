using EcoLoop.Api.DTOs;
using EcoLoop.Api.Models;

namespace EcoLoop.Api.Services.Interfaces;

public interface IProductImageService
{
    Task<List<ProductImage>> GetByProductIdAsync(Guid productId);
    Task<ProductImage?> CreateAsync(Guid productId, CreateProductImageRequest request);
    Task<ProductImage?> UpdateAsync(
        Guid productId,
        Guid imageId,
        UpdateProductImageRequest request);

    Task<bool> DeleteAsync(Guid productId, Guid imageId);
}