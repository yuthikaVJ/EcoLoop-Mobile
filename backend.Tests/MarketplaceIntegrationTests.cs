using System.Text.Json;
using EcoLoop.Api.DTOs;
using EcoLoop.Api.Models;
using EcoLoop.Api.Services;

namespace EcoLoop.Backend.Tests;

public class MarketplaceIntegrationTests
{
    private static JsonElement Json(object value) => JsonSerializer.SerializeToElement(
        value, new JsonSerializerOptions(JsonSerializerDefaults.Web));

    [Fact]
    public async Task PublishedMaterial_CatalogFieldsCanCreateTransaction()
    {
        await using var context = await Component4TestContext.CreateAsync();
        var listings = new MaterialListingService(context.Db);
        var published = await listings.CreateAsync(new CreateMaterialListingRequest
        {
            BusinessId = context.Seller.Id, Title = "Copper", Category = "METALS",
            Description = "Clean wire", Quantity = "500", Unit = "Kgs",
            Price = 35, PriceUnit = "Kg", Location = "Colombo", Type = 0,
            SellerDeliveryAvailable = true
        });
        var catalog = Json(await listings.GetAllAsync(null, null, null, 1, 100));
        var item = catalog.GetProperty("items")[0];
        Assert.Equal(published.Id, item.GetProperty("id").GetGuid());
        Assert.Equal(context.Seller.Id, item.GetProperty("businessId").GetGuid());
        Assert.Equal("Clean wire", item.GetProperty("description").GetString());
        var transaction = await new MaterialTransactionService(context.Db).CreateAsync(new()
        {
            MaterialListingId = item.GetProperty("id").GetGuid(),
            BuyerBusinessId = context.Buyer.Id,
            SellerBusinessId = item.GetProperty("businessId").GetGuid(),
            Quantity = 2, Unit = item.GetProperty("unit").GetString()!,
            UnitPrice = item.GetProperty("price").GetDecimal(),
            Delivery = new() { Method = 0 }
        });
        Assert.Null(transaction.Error);
        Assert.Equal(70m, transaction.Data!.TotalAmount);
        Assert.Equal("Colombo", transaction.Data.Delivery!.Location);
    }

    [Fact]
    public async Task MyListings_FiltersByBusinessAndPersistedStatus()
    {
        await using var context = await Component4TestContext.CreateAsync();
        var listing = await context.AddListingAsync();
        await context.AddListingAsync(type: ListingType.INeed);
        var service = new MaterialListingService(context.Db);
        Assert.True(await service.ChangeStatusAsync(listing.Id, 1));
        var active = Json(await service.GetAllAsync(null, null, null, 1, 100, context.Seller.Id));
        Assert.Equal(0, active.GetProperty("totalItems").GetInt32());
        var completed = Json(await service.GetAllAsync(null, null, null, 1, 100, context.Seller.Id, 1));
        Assert.Equal(listing.Id, completed.GetProperty("items")[0].GetProperty("id").GetGuid());
        Assert.True(await service.ChangeStatusAsync(listing.Id, 2));
        completed = Json(await service.GetAllAsync(null, null, null, 1, 100, context.Seller.Id, 1));
        Assert.Equal(0, completed.GetProperty("totalItems").GetInt32());
    }

    [Fact]
    public async Task ProductCatalog_CheckoutAndCancellationRefreshStock()
    {
        await using var context = await Component4TestContext.CreateAsync();
        var product = await context.AddProductAsync(quantity: 3);
        var catalog = new ProductService(context.Db);
        var items = Json(await catalog.GetProductsAsync(null, null, null, null, null, "newest", 1, 100));
        var item = items.GetProperty("items")[0];
        Assert.Equal(context.Seller.Id, item.GetProperty("businessId").GetGuid());
        Assert.Equal(3, item.GetProperty("availableQuantity").GetInt32());
        var orders = new ProductOrderService(context.Db);
        var order = await orders.CreateAsync(new()
        {
            BuyerBusinessId = context.Buyer.Id,
            Items = [new() { ProductId = item.GetProperty("id").GetGuid(), Quantity = 3 }],
            Delivery = new() { Method = 0 }
        });
        Assert.Null(order.Error);
        Assert.Equal(0, (await catalog.GetByIdAsync(product.Id))!.AvailableQuantity);
        var cancelled = await orders.ChangeStatusAsync(order.Data!.Id, context.Buyer.Id, ProductOrderStatus.Cancelled, null);
        Assert.Null(cancelled.Error);
        Assert.Equal(3, (await catalog.GetByIdAsync(product.Id))!.AvailableQuantity);
    }
}
