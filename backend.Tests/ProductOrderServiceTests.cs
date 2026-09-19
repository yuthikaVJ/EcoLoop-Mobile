using EcoLoop.Api.DTOs;
using EcoLoop.Api.Models;
using EcoLoop.Api.Services;
using Microsoft.EntityFrameworkCore;

namespace EcoLoop.Backend.Tests;

public class ProductOrderServiceTests
{
    [Fact]
    public async Task CreateOrder_SnapshotsProduct_DecrementsInventory_AndCreatesHistory()
    {
        await using var context = await Component4TestContext.CreateAsync();
        var product = await context.AddProductAsync(quantity: 5, sellerDelivery: true);
        var service = new ProductOrderService(context.Db);

        var result = await service.CreateAsync(Request(context, product, 2, DeliveryMethod.SellerDelivery));

        Assert.Null(result.Error);
        Assert.Equal(50m, result.Data?.TotalAmount);
        Assert.Single(result.Data!.Items);
        Assert.Equal(product.Name, result.Data.Items[0].ProductName);
        Assert.Single(result.Data.StatusHistory);
        Assert.Equal(3, (await context.Db.Inventories.SingleAsync(x => x.ProductId == product.Id)).Quantity);
    }

    [Fact]
    public async Task CreateOrder_PreventsOverselling()
    {
        await using var context = await Component4TestContext.CreateAsync();
        var product = await context.AddProductAsync(quantity: 1);
        var service = new ProductOrderService(context.Db);

        var result = await service.CreateAsync(Request(context, product, 2, DeliveryMethod.SelfPickup));

        Assert.Null(result.Data);
        Assert.Contains("Insufficient inventory", result.Error);
        Assert.Empty(await context.Db.ProductOrders.ToListAsync());
    }

    [Fact]
    public async Task CreateOrder_RejectsUnavailableSellerDelivery()
    {
        await using var context = await Component4TestContext.CreateAsync();
        var product = await context.AddProductAsync(sellerDelivery: false);
        var service = new ProductOrderService(context.Db);

        var result = await service.CreateAsync(Request(context, product, 1, DeliveryMethod.SellerDelivery));

        Assert.Null(result.Data);
        Assert.Contains("not available", result.Error);
    }

    [Fact]
    public async Task CancelOrder_RestoresInventory_AndCreatesHistory()
    {
        await using var context = await Component4TestContext.CreateAsync();
        var product = await context.AddProductAsync(quantity: 4);
        var service = new ProductOrderService(context.Db);
        var created = await service.CreateAsync(Request(context, product, 3, DeliveryMethod.SelfPickup));

        var cancelled = await service.ChangeStatusAsync(created.Data!.Id, context.Buyer.Id, ProductOrderStatus.Cancelled, "Changed mind");

        Assert.Equal(ProductOrderStatus.Cancelled.ToString(), cancelled.Data?.StatusName);
        Assert.Equal(2, cancelled.Data?.StatusHistory.Count);
        Assert.Equal(4, (await context.Db.Inventories.SingleAsync(x => x.ProductId == product.Id)).Quantity);
    }

    [Fact]
    public async Task ReadySelfPickup_CannotBeMarkedDelivered()
    {
        await using var context = await Component4TestContext.CreateAsync();
        var product = await context.AddProductAsync();
        var service = new ProductOrderService(context.Db);
        var created = await service.CreateAsync(Request(context, product, 1, DeliveryMethod.SelfPickup));
        await service.ChangeStatusAsync(created.Data!.Id, context.Seller.Id, ProductOrderStatus.Confirmed, null);
        await service.ChangeStatusAsync(created.Data.Id, context.Seller.Id, ProductOrderStatus.Processing, null);
        await service.ChangeStatusAsync(created.Data.Id, context.Seller.Id, ProductOrderStatus.Ready, null);

        var result = await service.ChangeStatusAsync(created.Data.Id, context.Seller.Id, ProductOrderStatus.Delivered, null);

        Assert.Null(result.Data);
        Assert.Contains("delivery method", result.Error);
    }

    [Fact]
    public async Task CreateOrder_RejectsProductsFromDifferentSellers()
    {
        await using var context = await Component4TestContext.CreateAsync();
        var first = await context.AddProductAsync(context.Seller);
        var second = await context.AddProductAsync(context.OtherSeller);
        var service = new ProductOrderService(context.Db);
        var request = Request(context, first, 1, DeliveryMethod.SelfPickup);
        request.Items.Add(new CreateProductOrderItemRequest { ProductId = second.Id, Quantity = 1 });

        var result = await service.CreateAsync(request);

        Assert.Null(result.Data);
        Assert.Contains("same seller", result.Error);
    }

    private static CreateProductOrderRequest Request(
        Component4TestContext context, Product product, int quantity, DeliveryMethod method) => new()
    {
        BuyerBusinessId = context.Buyer.Id,
        Items = [new CreateProductOrderItemRequest { ProductId = product.Id, Quantity = quantity }],
        Delivery = new DeliveryInputDto { Method = (int)method, Location = method == DeliveryMethod.SellerDelivery ? "Galle" : null }
    };
}
