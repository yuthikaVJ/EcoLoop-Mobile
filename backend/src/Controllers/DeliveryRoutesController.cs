using EcoLoop.Api.Services;
using Microsoft.AspNetCore.Mvc;

namespace EcoLoop.Api.Controllers;

[ApiController]
[Route("api/delivery-routes")]
public class DeliveryRoutesController(DeliveryRouteService service) : ControllerBase
{
    [HttpPost]
    public async Task<IActionResult> Calculate(DeliveryRouteRequest request, CancellationToken cancellationToken) =>
        Ok(await service.CalculateAsync(request, cancellationToken));

    [HttpGet("reverse")]
    public async Task<IActionResult> Reverse([FromQuery] double lat, [FromQuery] double lng, CancellationToken cancellationToken) =>
        Ok(await service.ReverseGeocodeAsync(lat, lng, cancellationToken));

    [HttpGet("geocode")]
    public async Task<IActionResult> Geocode([FromQuery] string q, CancellationToken cancellationToken) =>
        Ok(await service.GeocodeAsync(q, cancellationToken));
}
