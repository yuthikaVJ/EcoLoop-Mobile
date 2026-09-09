using EcoLoop.Api.Data;
using EcoLoop.Api.DTOs;
using EcoLoop.Api.Models;
using EcoLoop.Api.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace EcoLoop.Api.Services;

public class InventoryService : IInventoryService
{
    private readonly EcoLoopDbContext _db;

    public InventoryService(EcoLoopDbContext db)
    {
        _db = db;
    }

    public async Task<Inventory?> GetByProductIdAsync(Guid productId)
    {
        return await _db.Inventories
            .AsNoTracking()
            .FirstOrDefaultAsync(inventory =>
                inventory.ProductId == productId);
    }

    public async Task<Inventory?> CreateAsync(
        Guid productId,
        CreateInventoryRequest request)
    {
        var productExists = await _db.Products
            .AnyAsync(product => product.Id == productId);

        if (!productExists)
            return null;

        var existingInventory = await _db.Inventories
            .AnyAsync(inventory => inventory.ProductId == productId);

        if (existingInventory)
            return await GetByProductIdAsync(productId);

        var inventory = new Inventory
        {
            ProductId = productId,
            Quantity = request.Quantity,
            IsAvailable = request.Quantity > 0
        };

        _db.Inventories.Add(inventory);
        await _db.SaveChangesAsync();

        return inventory;
    }

    public async Task<Inventory?> UpdateAsync(
        Guid productId,
        UpdateInventoryRequest request)
    {
        var inventory = await _db.Inventories
            .FirstOrDefaultAsync(inventory =>
                inventory.ProductId == productId);

        if (inventory == null)
            return null;

        inventory.Quantity = request.Quantity;
        inventory.IsAvailable = request.IsAvailable &&
                                request.Quantity > 0;

        await _db.SaveChangesAsync();

        return inventory;
    }

    public async Task<bool> DeleteAsync(Guid productId)
    {
        var inventory = await _db.Inventories
            .FirstOrDefaultAsync(inventory =>
                inventory.ProductId == productId);

        if (inventory == null)
            return false;

        inventory.IsAvailable = false;
        inventory.Quantity = 0;

        await _db.SaveChangesAsync();

        return true;
    }
}