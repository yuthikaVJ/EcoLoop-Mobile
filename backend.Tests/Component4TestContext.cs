using EcoLoop.Api.Data;
using EcoLoop.Api.Models;
using Microsoft.Data.Sqlite;
using Microsoft.EntityFrameworkCore;

namespace EcoLoop.Backend.Tests;

public sealed class Component4TestContext : IAsyncDisposable
{
    private readonly SqliteConnection _connection;
    public EcoLoopDbContext Db { get; }
    public Business Buyer { get; } = new() { BusinessName = "Buyer" };
    public Business Seller { get; } = new() { BusinessName = "Seller", IsVerified = true };
    public Business OtherSeller { get; } = new() { BusinessName = "Other Seller" };

    private Component4TestContext(SqliteConnection connection, EcoLoopDbContext db)
    {
        _connection = connection;
        Db = db;
    }

    public static async Task<Component4TestContext> CreateAsync()
    {
        var connection = new SqliteConnection("Data Source=:memory:");
        await connection.OpenAsync();
        var options = new DbContextOptionsBuilder<EcoLoopDbContext>().UseSqlite(connection).Options;
        var db = new EcoLoopDbContext(options);
        await db.Database.EnsureCreatedAsync();
        var context = new Component4TestContext(connection, db);
        db.Businesses.AddRange(context.Buyer, context.Seller, context.OtherSeller);
        await db.SaveChangesAsync();
        return context;
    }

    public async Task<MaterialListing> AddListingAsync(bool sellerDelivery = false, ListingType type = ListingType.IHave)
    {
        var listing = new MaterialListing
        {
            BusinessId = type == ListingType.IHave ? Seller.Id : Buyer.Id,
            Title = "Recycled Material",
            Category = "PLASTICS",
            Description = "Clean material",
            Quantity = "10",
            Unit = "Tons",
            Location = "Colombo",
            Price = 100,
            PriceUnit = "Ton",
            DeliveryMethod = "Self Pickup",
            SellerDeliveryAvailable = sellerDelivery,
            Type = type
        };
        Db.MaterialListings.Add(listing);
        await Db.SaveChangesAsync();
        return listing;
    }

    public async Task<Product> AddProductAsync(Business? seller = null, int quantity = 10, bool sellerDelivery = false)
    {
        seller ??= Seller;
        var category = new ProductCategory { Name = $"Category {Guid.NewGuid()}" };
        var product = new Product
        {
            Category = category,
            BusinessId = seller.Id,
            Name = "Reusable Bottle",
            Description = "Bottle",
            MaterialType = "Metal",
            Price = 25,
            SellerDeliveryAvailable = sellerDelivery,
            Inventory = new Inventory { Quantity = quantity, IsAvailable = quantity > 0 }
        };
        Db.Products.Add(product);
        await Db.SaveChangesAsync();
        return product;
    }

    public async ValueTask DisposeAsync()
    {
        await Db.DisposeAsync();
        await _connection.DisposeAsync();
    }
}
