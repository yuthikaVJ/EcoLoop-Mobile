using System.Text.Json;

namespace EcoLoop.Api.Services;

public record DeliveryRouteRequest(string Origin, string Destination);
public record DeliveryRouteDto(int DistanceMeters, string Duration, string EncodedPolyline);

public class DeliveryRouteService(HttpClient client, IConfiguration configuration)
{
    public async Task<DeliveryRouteDto> CalculateAsync(DeliveryRouteRequest request, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(request.Origin) || request.Origin.Length > 500 ||
            string.IsNullOrWhiteSpace(request.Destination) || request.Destination.Length > 500)
            throw new TransactionRuleException(400, "Origin and destination must contain 1 to 500 characters.");
        var key = configuration["GoogleMaps:RoutesApiKey"];
        if (string.IsNullOrWhiteSpace(key))
            throw new TransactionRuleException(503, "Route estimates are not configured yet.");
        using var message = new HttpRequestMessage(HttpMethod.Post, "https://routes.googleapis.com/directions/v2:computeRoutes");
        message.Headers.Add("X-Goog-Api-Key", key);
        message.Headers.Add("X-Goog-FieldMask", "routes.duration,routes.distanceMeters,routes.polyline.encodedPolyline");
        message.Content = JsonContent.Create(new
        {
            origin = new { address = request.Origin.Trim() },
            destination = new { address = request.Destination.Trim() },
            travelMode = "DRIVE", units = "METRIC"
        });
        try
        {
            using var response = await client.SendAsync(message, cancellationToken);
            if (!response.IsSuccessStatusCode) throw new TransactionRuleException(502, "The map service could not calculate a route. Check the addresses or try later.");
            using var body = JsonDocument.Parse(await response.Content.ReadAsStringAsync(cancellationToken));
            if (!body.RootElement.TryGetProperty("routes", out var routes) || routes.GetArrayLength() == 0)
                throw new TransactionRuleException(404, "No driving route was found for these locations.");
            var route = routes[0];
            return new(route.GetProperty("distanceMeters").GetInt32(), route.GetProperty("duration").GetString()!,
                route.GetProperty("polyline").GetProperty("encodedPolyline").GetString()!);
        }
        catch (TaskCanceledException) when (!cancellationToken.IsCancellationRequested)
        {
            throw new TransactionRuleException(504, "Route calculation timed out. Try again.");
        }
        catch (HttpRequestException)
        {
            throw new TransactionRuleException(502, "The map service is unavailable. Try again later.");
        }
        catch (Exception exception) when (exception is JsonException or KeyNotFoundException or InvalidOperationException or FormatException)
        {
            throw new TransactionRuleException(502, "The map service returned an incomplete route. Try again later.");
        }
    }
}
