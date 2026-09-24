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
}
