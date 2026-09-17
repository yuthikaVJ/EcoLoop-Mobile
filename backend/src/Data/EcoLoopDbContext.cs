using EcoLoop.Api.Models;
using Microsoft.EntityFrameworkCore;

namespace EcoLoop.Api.Data;

public class EcoLoopDbContext : DbContext
{
    public EcoLoopDbContext(
        DbContextOptions<EcoLoopDbContext> options)
        : base(options)
    {
    }

    public DbSet<Product> Products => Set<Product>();
    public DbSet<ProductCategory> ProductCategories => Set<ProductCategory>();
    public DbSet<ProductImage> ProductImages => Set<ProductImage>();
    public DbSet<Inventory> Inventories => Set<Inventory>();
    public DbSet<Business> Businesses => Set<Business>();
    public DbSet<MaterialListing> MaterialListings => Set<MaterialListing>();
    public DbSet<RefreshToken> RefreshTokens => Set<RefreshToken>();
    public DbSet<ChatMessage> ChatMessages => Set<ChatMessage>();
    public DbSet<DeviceToken> DeviceTokens => Set<DeviceToken>();

    protected override void OnModelCreating(
        ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Product>()
            .Property(product => product.Price)
            .HasPrecision(12, 2);

        modelBuilder.Entity<Product>()
            .HasOne(product => product.Category)
            .WithMany(category => category.Products)
            .HasForeignKey(product => product.CategoryId)
            .OnDelete(DeleteBehavior.Restrict);

        modelBuilder.Entity<Product>()
            .HasOne(product => product.Business)
            .WithMany()
            .HasForeignKey(product => product.BusinessId)
            .OnDelete(DeleteBehavior.Restrict);

        modelBuilder.Entity<Product>()
            .HasOne(product => product.Inventory)
            .WithOne(inventory => inventory.Product)
            .HasForeignKey<Inventory>(
                inventory => inventory.ProductId);

        modelBuilder.Entity<Product>()
            .HasMany(product => product.Images)
            .WithOne(image => image.Product)
            .HasForeignKey(image => image.ProductId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<Product>()
            .HasIndex(product => product.Name);

        modelBuilder.Entity<Product>()
            .HasIndex(product => product.CategoryId);

        modelBuilder.Entity<Inventory>()
            .HasIndex(inventory => inventory.ProductId)
            .IsUnique();

        // ── MaterialListing configuration ──
        modelBuilder.Entity<MaterialListing>()
            .Property(listing => listing.Price)
            .HasPrecision(12, 2);

        modelBuilder.Entity<MaterialListing>()
            .HasOne(listing => listing.Business)
            .WithMany()
            .HasForeignKey(listing => listing.BusinessId)
            .OnDelete(DeleteBehavior.Restrict);

        modelBuilder.Entity<MaterialListing>()
            .HasIndex(listing => listing.Category);

        modelBuilder.Entity<MaterialListing>()
            .HasIndex(listing => listing.Type);

        modelBuilder.Entity<MaterialListing>()
            .HasIndex(listing => listing.Status);

        modelBuilder.Entity<MaterialListing>()
            .HasIndex(listing => listing.BusinessId);

        // ── ChatMessage configuration ──
        modelBuilder.Entity<ChatMessage>()
            .HasOne(m => m.Listing)
            .WithMany()
            .HasForeignKey(m => m.ListingId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<ChatMessage>()
            .HasOne(m => m.Sender)
            .WithMany()
            .HasForeignKey(m => m.SenderId)
            .OnDelete(DeleteBehavior.Restrict);

        modelBuilder.Entity<ChatMessage>()
            .HasOne(m => m.Receiver)
            .WithMany()
            .HasForeignKey(m => m.ReceiverId)
            .OnDelete(DeleteBehavior.Restrict);

        modelBuilder.Entity<ChatMessage>()
            .HasIndex(m => m.ListingId);

        // ── DeviceToken configuration ──
        modelBuilder.Entity<DeviceToken>()
            .HasOne(d => d.Business)
            .WithMany()
            .HasForeignKey(d => d.BusinessId)
            .OnDelete(DeleteBehavior.Cascade);
            
        modelBuilder.Entity<DeviceToken>()
            .HasIndex(d => d.BusinessId);
    }
}