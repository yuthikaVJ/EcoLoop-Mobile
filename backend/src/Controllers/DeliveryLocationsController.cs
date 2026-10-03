using EcoLoop.Api.DTOs;
using EcoLoop.Api.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace EcoLoop.Api.Controllers;

// Saved locations always belong to the signed-in business (from the JWT); the
// businessId query/body values sent by older clients are ignored.
[ApiController]
[Authorize]
[Route("api/delivery-locations")]
public class DeliveryLocationsController(DeliveryLocationService service) : ControllerBase
{
    [HttpGet]
    public async Task<IActionResult> List() => Ok(new { items = await service.ListAsync(User.BusinessId()) });

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> Get(Guid id) => Ok(await service.GetAsync(id, User.BusinessId()));

    [HttpPost]
    public async Task<IActionResult> Create(SaveDeliveryLocationRequest request)
    {
        request.BusinessId = User.BusinessId();
        var item = await service.SaveAsync(null, request);
        return CreatedAtAction(nameof(Get), new { id = item.Id }, item);
    }

    [HttpPut("{id:guid}")]
    public async Task<IActionResult> Update(Guid id, SaveDeliveryLocationRequest request)
    {
        request.BusinessId = User.BusinessId();
        return Ok(await service.SaveAsync(id, request));
    }

    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> Delete(Guid id)
    {
        await service.DeleteAsync(id, User.BusinessId());
        return NoContent();
    }
}
