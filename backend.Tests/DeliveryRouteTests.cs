using System.Net;
using EcoLoop.Api.Services;
using Microsoft.Extensions.Configuration;

namespace EcoLoop.Backend.Tests;

public class DeliveryRouteTests
{
    private sealed class Handler(Func<HttpRequestMessage, Task<HttpResponseMessage>> respond) : HttpMessageHandler
    {
        protected override Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken cancellationToken) => respond(request);
    }

    private const string OsrmOk =
        "{\"code\":\"Ok\",\"routes\":[{\"distance\":1500.4,\"duration\":299.6,\"geometry\":\"_p~iF~ps|U_ulLnnqC\"}]}";

    private static HttpResponseMessage Json(string body, HttpStatusCode status = HttpStatusCode.OK) =>
        new(status) { Content = new StringContent(body) };

    private static DeliveryRouteService Service(HttpClient client) =>
        new(client, new ConfigurationBuilder().Build());

    [Fact]
    public async Task Coordinates_GoStraightToOsrm_AndMapDistanceDurationAndGeometry()
    {
        var calls = new List<Uri>();
        using var client = new HttpClient(new Handler(request =>
        {
            calls.Add(request.RequestUri!);
            return Task.FromResult(Json(OsrmOk));
        }));

        var route = await Service(client).CalculateAsync(new("6.9271, 79.8612", "7.2906, 80.6337"), default);

        var call = Assert.Single(calls);
        Assert.Equal("router.project-osrm.org", call.Host);
        Assert.Contains("/route/v1/driving/79.8612,6.9271;80.6337,7.2906", call.AbsolutePath);
        Assert.Equal(1500, route.DistanceMeters);
        Assert.Equal("300s", route.Duration);
        Assert.Equal("_p~iF~ps|U_ulLnnqC", route.EncodedPolyline);
    }

    [Fact]
    public async Task Address_IsGeocodedWithNominatim_BeforeRouting()
    {
        var calls = new List<Uri>();
        using var client = new HttpClient(new Handler(request =>
        {
            calls.Add(request.RequestUri!);
            return Task.FromResult(request.RequestUri!.Host == "nominatim.openstreetmap.org"
                ? Json("[{\"lat\":\"7.2906\",\"lon\":\"80.6337\"}]")
                : Json(OsrmOk));
        }));

        await Service(client).CalculateAsync(new("6.9271, 79.8612", "Kandy"), default);

        Assert.Equal(2, calls.Count);
        Assert.Equal("nominatim.openstreetmap.org", calls[0].Host);
        Assert.Contains("q=Kandy", calls[0].Query);
        Assert.Contains("79.8612,6.9271;80.6337,7.2906", calls[1].AbsolutePath);
    }

    [Fact]
    public async Task UnknownAddress_Returns404_WithoutRouting()
    {
        using var client = new HttpClient(new Handler(request =>
        {
            Assert.Equal("nominatim.openstreetmap.org", request.RequestUri!.Host);
            return Task.FromResult(Json("[]"));
        }));

        var error = await Assert.ThrowsAsync<TransactionRuleException>(() =>
            Service(client).CalculateAsync(new("6.9271, 79.8612", "Nowhere-at-all"), default));
        Assert.Equal(404, error.StatusCode);
    }

    [Fact]
    public async Task ReverseGeocode_ReturnsDisplayName()
    {
        Uri? called = null;
        using var client = new HttpClient(new Handler(request =>
        {
            called = request.RequestUri;
            return Task.FromResult(Json("{\"display_name\":\"Galle Road, Kollupitiya, Colombo\"}"));
        }));

        var place = await Service(client).ReverseGeocodeAsync(6.9271, 79.8612, default);

        Assert.Equal("Galle Road, Kollupitiya, Colombo", place.Name);
        Assert.Equal("/reverse", called!.AbsolutePath);
        Assert.Contains("lat=6.9271&lon=79.8612", called.Query);
    }

    [Fact]
    public async Task ReverseGeocode_NoAddress_Returns404()
    {
        using var client = new HttpClient(new Handler(_ => Task.FromResult(Json("{\"error\":\"Unable to geocode\"}"))));

        var error = await Assert.ThrowsAsync<TransactionRuleException>(() =>
            Service(client).ReverseGeocodeAsync(0, 0, default));
        Assert.Equal(404, error.StatusCode);
    }

    [Fact]
    public async Task ReverseGeocode_InvalidCoordinates_Returns400_WithoutExternalCall()
    {
        using var client = new HttpClient(new Handler(_ => throw new Exception("Must not call provider")));

        var error = await Assert.ThrowsAsync<TransactionRuleException>(() =>
            Service(client).ReverseGeocodeAsync(95, 79.8612, default));
        Assert.Equal(400, error.StatusCode);
    }

    [Fact]
    public async Task NoRoute_Returns404()
    {
        using var client = new HttpClient(new Handler(_ =>
            Task.FromResult(Json("{\"code\":\"NoRoute\",\"message\":\"Impossible route\"}", HttpStatusCode.BadRequest))));

        var error = await Assert.ThrowsAsync<TransactionRuleException>(() =>
            Service(client).CalculateAsync(new("6.9271, 79.8612", "7.2906, 80.6337"), default));
        Assert.Equal(404, error.StatusCode);
    }
}
