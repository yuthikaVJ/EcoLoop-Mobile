using EcoLoop.Api.Models;
using Microsoft.EntityFrameworkCore;

namespace EcoLoop.Api.Data;

public class EcoLoopDbContext  : DbContext
{
    public EcoLoopDbContext(DbContextOptions<EcoLoopDbContext> options)
        : base(options)
    {
    }

    public DbSet<Product> Products => Set<Product>();
    public DbSet<ProductCategory> ProductCategories => Set<ProductCategory>();
    public DbSet<ProductImage> ProductImages => Set<ProductImage>();
    public DbSet<Inventory> Inventories => Set<Inventory>();
    public DbSet<Business> Businesses => Set<Business>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Product>()
            .Property(product => product.Price)
            .HasPrecision(12, 2);

        modelBuilder.Entity<Product>()
            .HasOne(product => product.Inventory)
            .WithOne(inventory => inventory.Product)
            .HasForeignKey<Inventory>(inventory => inventory.ProductId);

        modelBuilder.Entity<Product>()
            .HasMany(product => product.Images)
            .WithOne(image => image.Product)
            .HasForeignKey(image => image.ProductId);

        modelBuilder.Entity<Product>()
            .HasIndex(product => product.Name);

        modelBuilder.Entity<Product>()
            .HasIndex(product => product.CategoryId);
    }
}