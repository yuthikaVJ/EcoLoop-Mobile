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

    [Fact]
    public async Task MissingKey_IsExplicitlyUnavailable_WithoutExternalCall()
    {
        using var client = new HttpClient(new Handler(_ => throw new Exception("Must not call provider")));
        var service = new DeliveryRouteService(client, new ConfigurationBuilder().Build());
        Assert.Equal(503, (await Assert.ThrowsAsync<TransactionRuleException>(() => service.CalculateAsync(new("Colombo", "Kandy"), default))).StatusCode);
    }

    [Fact]
    public async Task RouteUsesServerKeyAndReturnsDistanceAndGeometry()
    {
        using var client = new HttpClient(new Handler(async request =>
        {
            Assert.Equal("routes.googleapis.com", request.RequestUri!.Host);
            Assert.Equal("test-key", request.Headers.GetValues("X-Goog-Api-Key").Single());
            Assert.Contains("routes.distanceMeters", request.Headers.GetValues("X-Goog-FieldMask").Single());
            Assert.Contains("Colombo", await request.Content!.ReadAsStringAsync());
            return new HttpResponseMessage(HttpStatusCode.OK)
            {
                Content = new StringContent("{\"routes\":[{\"distanceMeters\":1500,\"duration\":\"300s\",\"polyline\":{\"encodedPolyline\":\"test\"}}]}")
            };
        }));
        var config = new ConfigurationBuilder().AddInMemoryCollection(new Dictionary<string, string?> { ["GoogleMaps:RoutesApiKey"] = "test-key" }).Build();
        var route = await new DeliveryRouteService(client, config).CalculateAsync(new("Colombo", "Kandy"), default);
        Assert.Equal(1500, route.DistanceMeters);
        Assert.Equal("300s", route.Duration);
    }
}
