using System.Globalization;
using System.Text.Json;

namespace EcoLoop.Api.Services;

public record DeliveryRouteRequest(string Origin, string Destination);
public record DeliveryRouteDto(int DistanceMeters, string Duration, string EncodedPolyline);
public record GeocodedPlaceDto(double Lat, double Lng, string Name);

// Free, key-less routing: OpenStreetMap Nominatim for addresses, OSRM for the driving route.
public class DeliveryRouteService(HttpClient client, IConfiguration configuration)
{
    private string NominatimBaseUrl => (configuration["Routing:NominatimBaseUrl"] ?? "https://nominatim.openstreetmap.org").TrimEnd('/');
    private string OsrmBaseUrl => (configuration["Routing:OsrmBaseUrl"] ?? "https://router.project-osrm.org").TrimEnd('/');

    public async Task<DeliveryRouteDto> CalculateAsync(DeliveryRouteRequest request, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(request.Origin) || request.Origin.Length > 500 ||
            string.IsNullOrWhiteSpace(request.Destination) || request.Destination.Length > 500)
            throw new TransactionRuleException(400, "Origin and destination must contain 1 to 500 characters.");
        return await WithProviderErrors(async () =>
        {
            var origin = await ResolveAsync(request.Origin.Trim(), cancellationToken);
            var destination = await ResolveAsync(request.Destination.Trim(), cancellationToken);

            var url = string.Create(CultureInfo.InvariantCulture,
                $"{OsrmBaseUrl}/route/v1/driving/{origin.Lng},{origin.Lat};{destination.Lng},{destination.Lat}?overview=full&geometries=polyline");
            using var response = await client.GetAsync(url, cancellationToken);
            // OSRM answers 400 with code "NoRoute"/"NoSegment" when the points can't be connected.
            if (!response.IsSuccessStatusCode && response.StatusCode != System.Net.HttpStatusCode.BadRequest)
                throw new TransactionRuleException(502, "The map service could not calculate a route. Check the addresses or try later.");
            using var body = JsonDocument.Parse(await response.Content.ReadAsStringAsync(cancellationToken));
            if (body.RootElement.GetProperty("code").GetString() != "Ok" ||
                !body.RootElement.TryGetProperty("routes", out var routes) || routes.GetArrayLength() == 0)
                throw new TransactionRuleException(404, "No driving route was found for these locations.");
            var route = routes[0];
            // Same shape the Google Routes API returned, so the mobile client is unchanged.
            // OSRM "polyline" geometry uses the same precision-5 encoding.
            return new DeliveryRouteDto((int)Math.Round(route.GetProperty("distance").GetDouble()),
                string.Create(CultureInfo.InvariantCulture, $"{(int)Math.Round(route.GetProperty("duration").GetDouble())}s"),
                route.GetProperty("geometry").GetString()!);
        }, cancellationToken);
    }

    // Coordinates -> human-readable place name, for showing a GPS/map pick as an address.
    public async Task<GeocodedPlaceDto> ReverseGeocodeAsync(double lat, double lng, CancellationToken cancellationToken)
    {
        if (!double.IsFinite(lat) || !double.IsFinite(lng) || Math.Abs(lat) > 90 || Math.Abs(lng) > 180)
            throw new TransactionRuleException(400, "Latitude must be between -90 and 90 and longitude between -180 and 180.");
        return await WithProviderErrors(async () =>
        {
            var url = string.Create(CultureInfo.InvariantCulture,
                $"{NominatimBaseUrl}/reverse?lat={lat}&lon={lng}&format=jsonv2");
            using var response = await client.GetAsync(url, cancellationToken);
            if (!response.IsSuccessStatusCode)
                throw new TransactionRuleException(502, "The address lookup service is unavailable. Try again later.");
            using var body = JsonDocument.Parse(await response.Content.ReadAsStringAsync(cancellationToken));
            // Nominatim answers 200 with {"error": "Unable to geocode"} for places with no address (e.g. the sea).
            if (!body.RootElement.TryGetProperty("display_name", out var name) || string.IsNullOrWhiteSpace(name.GetString()))
                throw new TransactionRuleException(404, "No address was found for this location.");
            return new GeocodedPlaceDto(lat, lng, name.GetString()!);
        }, cancellationToken);
    }

    // Place name -> coordinates, so a saved address can be shown on the map again.
    public async Task<GeocodedPlaceDto> GeocodeAsync(string query, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(query) || query.Length > 500)
            throw new TransactionRuleException(400, "Location must contain 1 to 500 characters.");
        return await WithProviderErrors(async () =>
        {
            var (lat, lng) = await ResolveAsync(query.Trim(), cancellationToken);
            return new GeocodedPlaceDto(lat, lng, query.Trim());
        }, cancellationToken);
    }

    private static async Task<T> WithProviderErrors<T>(Func<Task<T>> call, CancellationToken cancellationToken)
    {
        try
        {
            return await call();
        }
        catch (TaskCanceledException) when (!cancellationToken.IsCancellationRequested)
        {
            throw new TransactionRuleException(504, "The map service timed out. Try again.");
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

    // "lat, lng" (what the app sends for GPS and map taps) is used directly; anything else is geocoded.
    private async Task<(double Lat, double Lng)> ResolveAsync(string location, CancellationToken cancellationToken)
    {
        if (TryParseCoordinates(location, out var point))
            return point;

        var url = $"{NominatimBaseUrl}/search?q={Uri.EscapeDataString(location)}&format=jsonv2&limit=1";
        using var response = await client.GetAsync(url, cancellationToken);
        if (!response.IsSuccessStatusCode)
            throw new TransactionRuleException(502, "The address lookup service is unavailable. Try again later.");
        using var body = JsonDocument.Parse(await response.Content.ReadAsStringAsync(cancellationToken));
        if (body.RootElement.GetArrayLength() == 0)
            throw new TransactionRuleException(404, $"Could not find '{location}' on the map.");
        var place = body.RootElement[0];
        return (double.Parse(place.GetProperty("lat").GetString()!, CultureInfo.InvariantCulture),
            double.Parse(place.GetProperty("lon").GetString()!, CultureInfo.InvariantCulture));
    }

    private static bool TryParseCoordinates(string text, out (double Lat, double Lng) point)
    {
        point = default;
        var parts = text.Split(',');
        if (parts.Length != 2 ||
            !double.TryParse(parts[0].Trim(), NumberStyles.Float, CultureInfo.InvariantCulture, out var lat) ||
            !double.TryParse(parts[1].Trim(), NumberStyles.Float, CultureInfo.InvariantCulture, out var lng) ||
            Math.Abs(lat) > 90 || Math.Abs(lng) > 180)
            return false;
        point = (lat, lng);
        return true;
    }
}
