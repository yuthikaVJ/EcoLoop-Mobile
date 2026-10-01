using EcoLoop.Api.Data;
using EcoLoop.Api.DTOs;
using EcoLoop.Api.Models;
using EcoLoop.Api.Services;
using Microsoft.EntityFrameworkCore;

namespace EcoLoop.Backend.Tests;

public class Component4EditingTests
{
    [Theory]
    [InlineData(0)]
    [InlineData(1)]
    public async Task ProductLifecycle_CompletesForItsDeliveryMethod_AndCannotCancelAfterward(int method)
    {
        await using var c = await Component4TestContext.CreateAsync();
        var product = await c.AddProductAsync(quantity: 5, sellerDelivery: true);
        var service = new ProductOrderService(c.Db);
        var order = (await service.CreateAsync(new()
        {
            BuyerBusinessId = c.Buyer.Id, Items = [new() { ProductId = product.Id, Quantity = 2 }],
            Delivery = new() { Method = method, Location = method == 1 ? "Buyer address" : null }
        })).Data!;
        await service.ChangeStatusAsync(order.Id, c.Seller.Id, ProductOrderStatus.Confirmed, null);
        await service.ChangeStatusAsync(order.Id, c.Seller.Id, ProductOrderStatus.Processing, null);
        if (method == 0)
        {
            Assert.Null((await service.ChangeStatusAsync(order.Id, c.Seller.Id, ProductOrderStatus.Ready, null)).Data);
            var current = (await service.GetByIdAsync(order.Id))!;
            await service.UpdateLocationAsync(order.Id, new() { ActingBusinessId = c.Seller.Id, Location = "Pickup point", ExpectedUpdatedAt = current.UpdatedAt });
        }
        Assert.NotNull((await service.ChangeStatusAsync(order.Id, c.Seller.Id, ProductOrderStatus.Ready, null)).Data);
        var terminal = method == 0 ? ProductOrderStatus.Completed : ProductOrderStatus.Delivered;
        Assert.Equal(terminal.ToString(), (await service.ChangeStatusAsync(order.Id, c.Seller.Id, terminal, null)).Data!.StatusName);
        Assert.Null((await service.ChangeStatusAsync(order.Id, c.Buyer.Id, ProductOrderStatus.Cancelled, null)).Data);
        Assert.Equal(3, (await c.Db.Inventories.SingleAsync()).Quantity);
    }

    [Fact]
    public async Task INeedListing_UsesListingOwnerAsBuyer_AndCompletes()
    {
        await using var c = await Component4TestContext.CreateAsync();
        var listing = await c.AddListingAsync(type: ListingType.INeed);
        var request = Request(c, listing);
        request.Delivery.Location = "Supplier pickup address";
        var service = new MaterialTransactionService(c.Db);
        var created = (await service.CreateAsync(request)).Data!;
        foreach (var next in new[] { MaterialTransactionStatus.Accepted, MaterialTransactionStatus.Processing, MaterialTransactionStatus.Ready, MaterialTransactionStatus.Completed })
            Assert.NotNull((await service.ChangeStatusAsync(created.Id, c.Seller.Id, next, null)).Data);
        Assert.Null((await service.ChangeStatusAsync(created.Id, c.Buyer.Id, MaterialTransactionStatus.Cancelled, null)).Data);
        Assert.Equal(5, (await service.GetByIdAsync(created.Id))!.StatusHistory.Count);
    }

    private static CreateMaterialTransactionRequest Request(Component4TestContext c, MaterialListing listing) => new()
    {
        MaterialListingId = listing.Id, BuyerBusinessId = c.Buyer.Id, SellerBusinessId = c.Seller.Id,
        Quantity = 1, Unit = "Tons", UnitPrice = 100, Delivery = new() { Method = 0 }
    };

    [Fact]
    public async Task PendingBuyerEdit_RecalculatesTotal_RecordsHistory_RejectsStaleEdit()
    {
        await using var c = await Component4TestContext.CreateAsync();
        var service = new MaterialTransactionService(c.Db);
        var created = (await service.CreateAsync(Request(c, await c.AddListingAsync()))).Data!;
        Assert.Equal("Colombo", created.Delivery!.Location);
        var edit = new UpdateMaterialTransactionRequest { ActingBusinessId = c.Buyer.Id, Quantity = 2.5m, Unit = "Tons", UnitPrice = 80 };
        var updated = await service.UpdateDetailsAsync(created.Id, edit);
        Assert.Equal(200m, updated.TotalAmount);
        Assert.Equal(2, updated.StatusHistory.Count);
        Assert.Contains("revised", updated.StatusHistory.Last().Note);
        Assert.Equal(409, (await Assert.ThrowsAsync<TransactionRuleException>(() => service.UpdateDetailsAsync(created.Id, edit))).StatusCode);
        edit.ExpectedUpdatedAt = updated.UpdatedAt;
        edit.ActingBusinessId = c.Seller.Id;
        Assert.Equal(403, (await Assert.ThrowsAsync<TransactionRuleException>(() => service.UpdateDetailsAsync(created.Id, edit))).StatusCode);
        await service.ChangeStatusAsync(created.Id, c.Seller.Id, MaterialTransactionStatus.Accepted, null);
        edit.ActingBusinessId = c.Buyer.Id;
        Assert.Equal(409, (await Assert.ThrowsAsync<TransactionRuleException>(() => service.UpdateDetailsAsync(created.Id, edit))).StatusCode);
    }

    [Fact]
    public async Task PickupAddress_OnlySellerCanEdit_BeforeReady()
    {
        await using var c = await Component4TestContext.CreateAsync();
        var service = new MaterialTransactionService(c.Db);
        var created = (await service.CreateAsync(Request(c, await c.AddListingAsync()))).Data!;
        var edit = new UpdateDeliveryLocationRequest { ActingBusinessId = c.Buyer.Id, Location = "Warehouse" };
        Assert.Equal(403, (await Assert.ThrowsAsync<TransactionRuleException>(() => service.UpdateLocationAsync(created.Id, edit))).StatusCode);
        edit.ActingBusinessId = c.Seller.Id;
        var updated = await service.UpdateLocationAsync(created.Id, edit);
        Assert.Equal("Warehouse", updated.Delivery!.Location);
        Assert.NotNull(updated.Delivery.UpdatedAt);
        await service.ChangeStatusAsync(created.Id, c.Seller.Id, MaterialTransactionStatus.Accepted, null);
        await service.ChangeStatusAsync(created.Id, c.Seller.Id, MaterialTransactionStatus.Processing, null);
        await service.ChangeStatusAsync(created.Id, c.Seller.Id, MaterialTransactionStatus.Ready, null);
        Assert.Equal(409, (await Assert.ThrowsAsync<TransactionRuleException>(() => service.UpdateLocationAsync(created.Id, edit))).StatusCode);
    }

    [Fact]
    public async Task SavedLocation_CRUD_Ownership_AndSnapshotPreservation()
    {
        await using var c = await Component4TestContext.CreateAsync();
        var service = new DeliveryLocationService(c.Db);
        var request = new SaveDeliveryLocationRequest { BusinessId = c.Buyer.Id, Label = "Home", Address = "Kandy", Latitude = 7.29, Longitude = 80.63 };
        var saved = await service.SaveAsync(null, request);
        Assert.Single(await service.ListAsync(c.Buyer.Id));
        Assert.Empty(await service.ListAsync(c.Seller.Id));
        Assert.Equal(404, (await Assert.ThrowsAsync<TransactionRuleException>(() => service.GetAsync(saved.Id, c.Seller.Id))).StatusCode);
        var transactionRequest = Request(c, await c.AddListingAsync(sellerDelivery: true));
        transactionRequest.Delivery = new() { Method = 1, Location = saved.Address };
        var transactions = new MaterialTransactionService(c.Db);
        var transaction = (await transactions.CreateAsync(transactionRequest)).Data!;
        request.ExpectedUpdatedAt = saved.UpdatedAt;
        request.Address = "Galle";
        var updated = await service.SaveAsync(saved.Id, request);
        Assert.Equal("Galle", updated.Address);
        await service.DeleteAsync(saved.Id, c.Buyer.Id);
        Assert.Empty(await service.ListAsync(c.Buyer.Id));
        Assert.Equal("Kandy", (await transactions.GetByIdAsync(transaction.Id))!.Delivery!.Location);
    }

    [Fact]
    public async Task LocationCoordinates_AndOversizedTerms_AreRejected()
    {
        await using var c = await Component4TestContext.CreateAsync();
        var locations = new DeliveryLocationService(c.Db);
        await Assert.ThrowsAsync<TransactionRuleException>(() => locations.SaveAsync(null,
            new() { BusinessId = c.Buyer.Id, Label = "Bad", Address = "Here", Latitude = 91, Longitude = 80 }));
        var request = Request(c, await c.AddListingAsync());
        request.Quantity = decimal.MaxValue;
        var result = await new MaterialTransactionService(c.Db).CreateAsync(request);
        Assert.Null(result.Data);
        Assert.Empty(await c.Db.MaterialTransactions.ToListAsync());
    }

    [Fact]
    public async Task StaleCancellation_RollsBackStockAndHistory()
    {
        await using var c = await Component4TestContext.CreateAsync();
        var product = await c.AddProductAsync(quantity: 5);
        var staleService = new ProductOrderService(c.Db);
        var created = (await staleService.CreateAsync(new()
        {
            BuyerBusinessId = c.Buyer.Id, Items = [new() { ProductId = product.Id, Quantity = 2 }], Delivery = new() { Method = 0 }
        })).Data!;
        var options = new DbContextOptionsBuilder<EcoLoopDbContext>().UseSqlite(c.Db.Database.GetDbConnection()).Options;
        await using (var other = new EcoLoopDbContext(options))
        {
            var result = await new ProductOrderService(other).ChangeStatusAsync(created.Id, c.Buyer.Id, ProductOrderStatus.Cancelled, null);
            Assert.NotNull(result.Data);
        }
        await Assert.ThrowsAsync<DbUpdateConcurrencyException>(() => staleService.ChangeStatusAsync(created.Id, c.Buyer.Id, ProductOrderStatus.Cancelled, null));
        c.Db.ChangeTracker.Clear();
        Assert.Equal(5, (await c.Db.Inventories.SingleAsync()).Quantity);
        Assert.Equal(2, await c.Db.ProductOrderStatusHistories.CountAsync());
    }

    [Fact]
    public async Task StaleMaterialTransition_CannotOverwriteAnotherDecision()
    {
        await using var c = await Component4TestContext.CreateAsync();
        var service = new MaterialTransactionService(c.Db);
        var created = (await service.CreateAsync(Request(c, await c.AddListingAsync()))).Data!;
        var options = new DbContextOptionsBuilder<EcoLoopDbContext>().UseSqlite(c.Db.Database.GetDbConnection()).Options;
        await using (var other = new EcoLoopDbContext(options))
            await new MaterialTransactionService(other).ChangeStatusAsync(created.Id, c.Seller.Id, MaterialTransactionStatus.Rejected, null);
        await Assert.ThrowsAsync<DbUpdateConcurrencyException>(() => service.ChangeStatusAsync(created.Id, c.Seller.Id, MaterialTransactionStatus.Accepted, null));
        c.Db.ChangeTracker.Clear();
        Assert.Equal(MaterialTransactionStatus.Rejected, (await c.Db.MaterialTransactions.SingleAsync()).Status);
        Assert.Equal(2, await c.Db.MaterialTransactionStatusHistories.CountAsync());
    }
}
