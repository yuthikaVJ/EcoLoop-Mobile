using EcoLoop.Api.DTOs;
using EcoLoop.Api.Models;

namespace EcoLoop.Api.Services.Interfaces;

public interface IInventoryService
{
    Task<Inventory?> GetByProductIdAsync(Guid productId);
    Task<Inventory?> CreateAsync(Guid productId, CreateInventoryRequest request);
    Task<Inventory?> UpdateAsync(Guid productId, UpdateInventoryRequest request);
    Task<bool> DeleteAsync(Guid productId);
}