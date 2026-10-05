using EcoLoop.Api.DTOs;
using EcoLoop.Api.Models;

namespace EcoLoop.Api.Services.Interfaces;

public interface ICategoryService
{
    Task<List<ProductCategory>> GetAllAsync();
    Task<ProductCategory?> GetByIdAsync(Guid id);
    Task<ProductCategory> CreateAsync(CreateCategoryRequest request);
    Task<ProductCategory?> UpdateAsync(Guid id, UpdateCategoryRequest request);
    Task<bool> DeleteAsync(Guid id);
}
