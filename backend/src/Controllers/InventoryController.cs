using EcoLoop.Api.DTOs;
using EcoLoop.Api.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace EcoLoop.Api.Controllers;

[ApiController]
[Route("api/products/{productId:guid}/inventory")]
public class InventoryController : ControllerBase
{
    private readonly IInventoryService _service;

    public InventoryController(IInventoryService service)
    {
        _service = service;
    }

    [HttpGet]
    public async Task<IActionResult> GetInventory(Guid productId)
    {
        var inventory = await _service.GetByProductIdAsync(productId);

        return inventory == null
            ? NotFound()
            : Ok(inventory);
    }

    [HttpPost]
    public async Task<IActionResult> CreateInventory(
        Guid productId,
        CreateInventoryRequest request)
    {
        var inventory = await _service.CreateAsync(productId, request);

        return inventory == null
            ? NotFound(new { message = "Product not found." })
            : Ok(inventory);
    }

    [HttpPut]
    public async Task<IActionResult> UpdateInventory(
        Guid productId,
        UpdateInventoryRequest request)
    {
        var inventory = await _service.UpdateAsync(productId, request);

        return inventory == null
            ? NotFound()
            : Ok(inventory);
    }

    [HttpDelete]
    public async Task<IActionResult> DeleteInventory(Guid productId)
    {
        return await _service.DeleteAsync(productId)
            ? NoContent()
            : NotFound();
    }
}