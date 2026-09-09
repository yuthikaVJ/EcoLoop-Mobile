using EcoLoop.Api.DTOs;

namespace EcoLoop.Api.Services.Interfaces;

public interface IProductService
{
    Task<object> GetProductsAsync(
        string? search,
        Guid? categoryId,
        string? materialType,
        decimal? minPrice,
        decimal? maxPrice,
        string sort,
        int page,
        int pageSize);

    Task<ProductDetailsDto?> GetByIdAsync(Guid id);
    Task<ProductDetailsDto> CreateAsync(CreateProductRequest request);
    Task<ProductDetailsDto?> UpdateAsync(Guid id, UpdateProductRequest request);
    Task<bool> DisableAsync(Guid id);
}