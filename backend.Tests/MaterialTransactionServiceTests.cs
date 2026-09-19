using EcoLoop.Api.DTOs;
using EcoLoop.Api.Models;
using EcoLoop.Api.Services;
using Microsoft.EntityFrameworkCore;

namespace EcoLoop.Backend.Tests;

public class MaterialTransactionServiceTests
{
    [Fact]
    public async Task Create_AddsPendingTransactionDeliveryAndHistory()
    {
        await using var context = await Component4TestContext.CreateAsync();
        var listing = await context.AddListingAsync(sellerDelivery: true);
        var service = new MaterialTransactionService(context.Db);

        var result = await service.CreateAsync(new CreateMaterialTransactionRequest
        {
            MaterialListingId = listing.Id,
            BuyerBusinessId = context.Buyer.Id,
            SellerBusinessId = context.Seller.Id,
            Quantity = 2.5m,
            Unit = "Tons",
            UnitPrice = 100,
            Delivery = new DeliveryInputDto { Method = (int)DeliveryMethod.SellerDelivery, Location = "Kandy" }
        });

        Assert.Null(result.Error);
        Assert.NotNull(result.Data);
        Assert.Equal(MaterialTransactionStatus.Pending.ToString(), result.Data.StatusName);
        Assert.Equal(250m, result.Data.TotalAmount);
        Assert.Single(result.Data.StatusHistory);
        Assert.Equal("Kandy", result.Data.Delivery?.Location);
    }

    [Fact]
    public async Task Create_RejectsUnavailableSellerDelivery()
    {
        await using var context = await Component4TestContext.CreateAsync();
        var listing = await context.AddListingAsync(sellerDelivery: false);
        var service = new MaterialTransactionService(context.Db);

        var result = await service.CreateAsync(Request(context, listing, DeliveryMethod.SellerDelivery));

        Assert.Null(result.Data);
        Assert.Contains("not available", result.Error);
        Assert.Empty(await context.Db.MaterialTransactions.ToListAsync());
    }

    [Fact]
    public async Task SellerCanAccept_BuyerCannotAccept_AndHistoryIsCreated()
    {
        await using var context = await Component4TestContext.CreateAsync();
        var listing = await context.AddListingAsync();
        var service = new MaterialTransactionService(context.Db);
        var created = await service.CreateAsync(Request(context, listing, DeliveryMethod.SelfPickup));

        var buyerAttempt = await service.ChangeStatusAsync(created.Data!.Id, context.Buyer.Id, MaterialTransactionStatus.Accepted, null);
        var accepted = await service.ChangeStatusAsync(created.Data.Id, context.Seller.Id, MaterialTransactionStatus.Accepted, "Accepted");

        Assert.Null(buyerAttempt.Data);
        Assert.Contains("Only the seller", buyerAttempt.Error);
        Assert.Equal(MaterialTransactionStatus.Accepted.ToString(), accepted.Data?.StatusName);
        Assert.Equal(2, accepted.Data?.StatusHistory.Count);
    }

    [Fact]
    public async Task InvalidStatusSkipIsRejected()
    {
        await using var context = await Component4TestContext.CreateAsync();
        var listing = await context.AddListingAsync();
        var service = new MaterialTransactionService(context.Db);
        var created = await service.CreateAsync(Request(context, listing, DeliveryMethod.SelfPickup));

        var result = await service.ChangeStatusAsync(created.Data!.Id, context.Seller.Id, MaterialTransactionStatus.Ready, null);

        Assert.Null(result.Data);
        Assert.Contains("Cannot change", result.Error);
    }

    private static CreateMaterialTransactionRequest Request(Component4TestContext context, MaterialListing listing, DeliveryMethod method) => new()
    {
        MaterialListingId = listing.Id,
        BuyerBusinessId = context.Buyer.Id,
        SellerBusinessId = context.Seller.Id,
        Quantity = 1,
        Unit = "Tons",
        UnitPrice = 100,
        Delivery = new DeliveryInputDto { Method = (int)method, Location = method == DeliveryMethod.SellerDelivery ? "Kandy" : null }
    };
}
