using EcoLoop.Api.Data;
using EcoLoop.Api.DTOs;
using EcoLoop.Api.Models;
using EcoLoop.Api.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace EcoLoop.Api.Services;

public class CategoryService : ICategoryService
{
    private readonly EcoLoopDbContext _db;

    public CategoryService(EcoLoopDbContext db)
    {
        _db = db;
    }

    public async Task<List<ProductCategory>> GetAllAsync()
    {
        return await _db.ProductCategories
            .AsNoTracking()
            .Where(category => category.IsActive)
            .OrderBy(category => category.Name)
            .ToListAsync();
    }

    public async Task<ProductCategory?> GetByIdAsync(Guid id)
    {
        return await _db.ProductCategories
            .FirstOrDefaultAsync(category =>
                category.Id == id && category.IsActive);
    }

    public async Task<ProductCategory> CreateAsync(
        CreateCategoryRequest request)
    {
        var category = new ProductCategory
        {
            Name = request.Name,
            Description = request.Description,
            IsActive = true
        };

        _db.ProductCategories.Add(category);
        await _db.SaveChangesAsync();

        return category;
    }

    public async Task<ProductCategory?> UpdateAsync(
        Guid id,
        UpdateCategoryRequest request)
    {
        var category = await _db.ProductCategories
            .FirstOrDefaultAsync(category => category.Id == id);

        if (category == null)
            return null;

        category.Name = request.Name;
        category.Description = request.Description;

        await _db.SaveChangesAsync();

        return category;
    }

    public async Task<bool> DeleteAsync(Guid id)
    {
        var category = await _db.ProductCategories
            .FirstOrDefaultAsync(category => category.Id == id);

        if (category == null)
            return false;

        category.IsActive = false;
        await _db.SaveChangesAsync();

        return true;
    }
}