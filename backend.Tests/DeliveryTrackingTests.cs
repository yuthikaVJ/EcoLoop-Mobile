using EcoLoop.Api.DTOs;
using EcoLoop.Api.Models;
using EcoLoop.Api.Services;

namespace EcoLoop.Backend.Tests;

public class DeliveryTrackingTests
{
    private static DeliveryTrackingService Tracking(Component4TestContext c) =>
        new(c.Db, new MaterialTransactionService(c.Db), new ProductOrderService(c.Db));

    private static async Task<ProductOrderDetailsDto> ReadyProductOrderAsync(Component4TestContext c, int method = 1)
    {
        var product = await c.AddProductAsync(quantity: 5, sellerDelivery: true);
        var orders = new ProductOrderService(c.Db);
        var order = (await orders.CreateAsync(new()
        {
            BuyerBusinessId = c.Buyer.Id, Items = [new() { ProductId = product.Id, Quantity = 1 }],
            Delivery = new() { Method = method, Location = "Buyer address, Kandy" }
        })).Data!;
        foreach (var next in new[] { ProductOrderStatus.Confirmed, ProductOrderStatus.Processing, ProductOrderStatus.Ready })
            Assert.NotNull((await orders.ChangeStatusAsync(order.Id, c.Seller.Id, next, null)).Data);
        return (await orders.GetByIdAsync(order.Id))!;
    }

    [Fact]
    public async Task SellerDeliversProduct_StartShareLocationDeliver_CompletesOrder()
    {
        await using var c = await Component4TestContext.CreateAsync();
        var order = await ReadyProductOrderAsync(c);
        var tracking = Tracking(c);

        var job = Assert.Single(await tracking.GetForSellerAsync(c.Seller.Id, includeFinished: false));
        Assert.Equal("product", job.Kind);
        Assert.Equal("Buyer", job.Buyer);
        Assert.Equal("NotStarted", job.StatusName);

        Assert.Equal("OnTheWay", (await tracking.StartAsync(job.Id, c.Seller.Id)).StatusName);
        var moving = await tracking.UpdatePositionAsync(job.Id, c.Seller.Id, new() { Latitude = 7.29, Longitude = 80.63 });
        Assert.Equal(7.29, moving.CurrentLatitude);
        Assert.NotNull(moving.LocationUpdatedAt);

        var done = await tracking.MarkDeliveredAsync(job.Id, c.Seller.Id);
        Assert.Equal("Delivered", done.StatusName);
        Assert.Equal("Delivered", done.ParentStatusName);

        // The buyer's view of the order shows the delivery progress, and history records it.
        var buyerView = (await new ProductOrderService(c.Db).GetByIdAsync(order.Id))!;
        Assert.Equal("Delivered", buyerView.Delivery!.StatusName);
        Assert.Contains(buyerView.StatusHistory, h => h.Note == "Delivered by seller");
        Assert.Empty(await tracking.GetForSellerAsync(c.Seller.Id, includeFinished: false));
    }

    [Fact]
    public async Task SellerDeliversMaterial_CompletesTransaction()
    {
        await using var c = await Component4TestContext.CreateAsync();
        var listing = await c.AddListingAsync(sellerDelivery: true);
        var materials = new MaterialTransactionService(c.Db);
        var created = (await materials.CreateAsync(new()
        {
            MaterialListingId = listing.Id, BuyerBusinessId = c.Buyer.Id, SellerBusinessId = c.Seller.Id,
            Quantity = 1, Unit = "Tons", UnitPrice = 100, Delivery = new() { Method = 1, Location = "Buyer yard, Galle" }
        })).Data!;
        foreach (var next in new[] { MaterialTransactionStatus.Accepted, MaterialTransactionStatus.Processing, MaterialTransactionStatus.Ready })
            Assert.NotNull((await materials.ChangeStatusAsync(created.Id, c.Seller.Id, next, null)).Data);
        var tracking = Tracking(c);
        var job = Assert.Single(await tracking.GetForSellerAsync(c.Seller.Id, false));
        Assert.Equal("Recycled Material", job.Title);

        await tracking.StartAsync(job.Id, c.Seller.Id);
        await tracking.MarkDeliveredAsync(job.Id, c.Seller.Id);

        Assert.Equal("Completed", (await materials.GetByIdAsync(created.Id))!.StatusName);
    }

    [Fact]
    public async Task CannotStartBeforeReady_OrAsBuyer_OrShareLocationBeforeStart()
    {
        await using var c = await Component4TestContext.CreateAsync();
        var product = await c.AddProductAsync(quantity: 5, sellerDelivery: true);
        await new ProductOrderService(c.Db).CreateAsync(new()
        {
            BuyerBusinessId = c.Buyer.Id, Items = [new() { ProductId = product.Id, Quantity = 1 }],
            Delivery = new() { Method = 1, Location = "Buyer address" }
        });
        var tracking = Tracking(c);
        var job = Assert.Single(await tracking.GetForSellerAsync(c.Seller.Id, false));

        Assert.Equal(409, (await Assert.ThrowsAsync<TransactionRuleException>(() => tracking.StartAsync(job.Id, c.Seller.Id))).StatusCode);
        Assert.Equal(403, (await Assert.ThrowsAsync<TransactionRuleException>(() => tracking.StartAsync(job.Id, c.Buyer.Id))).StatusCode);
        Assert.Equal(409, (await Assert.ThrowsAsync<TransactionRuleException>(() =>
            tracking.UpdatePositionAsync(job.Id, c.Seller.Id, new() { Latitude = 7, Longitude = 80 }))).StatusCode);
        Assert.Equal(409, (await Assert.ThrowsAsync<TransactionRuleException>(() => tracking.MarkDeliveredAsync(job.Id, c.Seller.Id))).StatusCode);
    }

    [Fact]
    public async Task BuyerConfirmsReceiptFirst_JobLeavesActiveList()
    {
        await using var c = await Component4TestContext.CreateAsync();
        var listing = await c.AddListingAsync(sellerDelivery: true);
        var materials = new MaterialTransactionService(c.Db);
        var created = (await materials.CreateAsync(new()
        {
            MaterialListingId = listing.Id, BuyerBusinessId = c.Buyer.Id, SellerBusinessId = c.Seller.Id,
            Quantity = 1, Unit = "Tons", UnitPrice = 100, Delivery = new() { Method = 1, Location = "Buyer yard" }
        })).Data!;
        foreach (var next in new[] { MaterialTransactionStatus.Accepted, MaterialTransactionStatus.Processing, MaterialTransactionStatus.Ready })
            await materials.ChangeStatusAsync(created.Id, c.Seller.Id, next, null);
        Assert.NotNull((await materials.ChangeStatusAsync(created.Id, c.Buyer.Id, MaterialTransactionStatus.Completed, null)).Data);

        var tracking = Tracking(c);
        Assert.Empty(await tracking.GetForSellerAsync(c.Seller.Id, includeFinished: false));
        Assert.Single(await tracking.GetForSellerAsync(c.Seller.Id, includeFinished: true));
    }

    [Fact]
    public async Task SelfPickupOrders_AreNotDeliveryJobs()
    {
        await using var c = await Component4TestContext.CreateAsync();
        await ReadyProductOrderAsync(c, method: 0);
        Assert.Empty(await Tracking(c).GetForSellerAsync(c.Seller.Id, includeFinished: true));
    }
}
