using System.Security.Claims;

namespace EcoLoop.Api.Controllers;

public static class BusinessClaims
{
    // The JWT issued by AuthController carries the business ID as NameIdentifier.
    // Endpoints marked [Authorize] can rely on it being present.
    public static Guid BusinessId(this ClaimsPrincipal user) =>
        Guid.TryParse(user.FindFirstValue(ClaimTypes.NameIdentifier), out var id)
            ? id
            : throw new InvalidOperationException("Authenticated user has no business ID claim.");
}
