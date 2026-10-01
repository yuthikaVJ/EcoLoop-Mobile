using EcoLoop.Api.DTOs;
using EcoLoop.Api.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace EcoLoop.Api.Controllers;

// Seller Delivery jobs for the signed-in seller (the seller is the driver).
[ApiController]
[Authorize]
[Route("api/deliveries")]
public class DeliveriesController(DeliveryTrackingService service) : ControllerBase
{
    [HttpGet("mine")]
    public async Task<IActionResult> Mine([FromQuery] bool includeFinished = false) =>
        Ok(new { items = await service.GetForSellerAsync(User.BusinessId(), includeFinished) });

    [HttpPost("{id:guid}/start")]
    public async Task<IActionResult> Start(Guid id) =>
        Ok(await service.StartAsync(id, User.BusinessId()));

    [HttpPut("{id:guid}/position")]
    public async Task<IActionResult> UpdatePosition(Guid id, DeliveryPositionRequest request) =>
        Ok(await service.UpdatePositionAsync(id, User.BusinessId(), request));

    [HttpPost("{id:guid}/delivered")]
    public async Task<IActionResult> Delivered(Guid id) =>
        Ok(await service.MarkDeliveredAsync(id, User.BusinessId()));
}
