using EcoLoop.Api.DTOs;
using EcoLoop.Api.Services;
using Microsoft.AspNetCore.Mvc;

namespace EcoLoop.Api.Controllers;

[ApiController]
[Route("api/delivery-locations")]
public class DeliveryLocationsController(DeliveryLocationService service) : ControllerBase
{
    [HttpGet]
    public async Task<IActionResult> List(Guid businessId) => Ok(new { items = await service.ListAsync(businessId) });

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> Get(Guid id, Guid businessId) => Ok(await service.GetAsync(id, businessId));

    [HttpPost]
    public async Task<IActionResult> Create(SaveDeliveryLocationRequest request)
    {
        var item = await service.SaveAsync(null, request);
        return CreatedAtAction(nameof(Get), new { id = item.Id, businessId = request.BusinessId }, item);
    }

    [HttpPut("{id:guid}")]
    public async Task<IActionResult> Update(Guid id, SaveDeliveryLocationRequest request) => Ok(await service.SaveAsync(id, request));

    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> Delete(Guid id, Guid businessId)
    {
        await service.DeleteAsync(id, businessId);
        return NoContent();
    }
}
