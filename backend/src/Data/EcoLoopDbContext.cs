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
    public DbSet<MaterialTransaction> MaterialTransactions => Set<MaterialTransaction>();
    public DbSet<MaterialTransactionStatusHistory> MaterialTransactionStatusHistories => Set<MaterialTransactionStatusHistory>();
    public DbSet<ProductOrder> ProductOrders => Set<ProductOrder>();
    public DbSet<ProductOrderItem> ProductOrderItems => Set<ProductOrderItem>();
    public DbSet<ProductOrderStatusHistory> ProductOrderStatusHistories => Set<ProductOrderStatusHistory>();
    public DbSet<Delivery> Deliveries => Set<Delivery>();

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

        ConfigureMaterialTransactions(modelBuilder);
        ConfigureProductOrders(modelBuilder);
        ConfigureDeliveries(modelBuilder);
    }

    private static void ConfigureMaterialTransactions(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<MaterialTransaction>(entity =>
        {
            entity.ToTable(table =>
            {
                table.HasCheckConstraint("CK_MaterialTransactions_Quantity", "\"Quantity\" > 0");
                table.HasCheckConstraint("CK_MaterialTransactions_Amounts", "\"UnitPrice\" >= 0 AND \"TotalAmount\" >= 0");
                table.HasCheckConstraint("CK_MaterialTransactions_DifferentParties", "\"BuyerBusinessId\" <> \"SellerBusinessId\"");
            });
            entity.Property(x => x.Quantity).HasPrecision(12, 3);
            entity.Property(x => x.UnitPrice).HasPrecision(12, 2);
            entity.Property(x => x.TotalAmount).HasPrecision(12, 2);
            entity.Property(x => x.Unit).HasMaxLength(50);
            entity.HasOne(x => x.MaterialListing).WithMany(x => x.Transactions).HasForeignKey(x => x.MaterialListingId).OnDelete(DeleteBehavior.Restrict);
            entity.HasOne(x => x.BuyerBusiness).WithMany().HasForeignKey(x => x.BuyerBusinessId).OnDelete(DeleteBehavior.Restrict);
            entity.HasOne(x => x.SellerBusiness).WithMany().HasForeignKey(x => x.SellerBusinessId).OnDelete(DeleteBehavior.Restrict);
            entity.HasIndex(x => x.MaterialListingId);
            entity.HasIndex(x => x.Status);
            entity.HasIndex(x => new { x.BuyerBusinessId, x.CreatedAt });
            entity.HasIndex(x => new { x.SellerBusinessId, x.CreatedAt });
        });

        modelBuilder.Entity<MaterialTransactionStatusHistory>(entity =>
        {
            entity.Property(x => x.Note).HasMaxLength(500);
            entity.HasOne(x => x.MaterialTransaction).WithMany(x => x.StatusHistory).HasForeignKey(x => x.MaterialTransactionId).OnDelete(DeleteBehavior.Cascade);
            entity.HasOne(x => x.ChangedByBusiness).WithMany().HasForeignKey(x => x.ChangedByBusinessId).OnDelete(DeleteBehavior.Restrict);
            entity.HasIndex(x => new { x.MaterialTransactionId, x.CreatedAt });
        });
    }

    private static void ConfigureProductOrders(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<ProductOrder>(entity =>
        {
            entity.ToTable(table =>
            {
                table.HasCheckConstraint("CK_ProductOrders_TotalAmount", "\"TotalAmount\" >= 0");
                table.HasCheckConstraint("CK_ProductOrders_DifferentParties", "\"BuyerBusinessId\" <> \"SellerBusinessId\"");
            });
            entity.Property(x => x.TotalAmount).HasPrecision(12, 2);
            entity.HasOne(x => x.BuyerBusiness).WithMany().HasForeignKey(x => x.BuyerBusinessId).OnDelete(DeleteBehavior.Restrict);
            entity.HasOne(x => x.SellerBusiness).WithMany().HasForeignKey(x => x.SellerBusinessId).OnDelete(DeleteBehavior.Restrict);
            entity.HasIndex(x => x.Status);
            entity.HasIndex(x => new { x.BuyerBusinessId, x.CreatedAt });
            entity.HasIndex(x => new { x.SellerBusinessId, x.CreatedAt });
        });

        modelBuilder.Entity<ProductOrderItem>(entity =>
        {
            entity.ToTable(table =>
            {
                table.HasCheckConstraint("CK_ProductOrderItems_Quantity", "\"Quantity\" > 0");
                table.HasCheckConstraint("CK_ProductOrderItems_Amounts", "\"UnitPrice\" >= 0 AND \"LineTotal\" >= 0");
            });
            entity.Property(x => x.ProductName).HasMaxLength(200);
            entity.Property(x => x.UnitPrice).HasPrecision(12, 2);
            entity.Property(x => x.LineTotal).HasPrecision(12, 2);
            entity.HasOne(x => x.ProductOrder).WithMany(x => x.Items).HasForeignKey(x => x.ProductOrderId).OnDelete(DeleteBehavior.Cascade);
            entity.HasOne(x => x.Product).WithMany(x => x.OrderItems).HasForeignKey(x => x.ProductId).OnDelete(DeleteBehavior.Restrict);
            entity.HasIndex(x => new { x.ProductOrderId, x.ProductId }).IsUnique();
        });

        modelBuilder.Entity<ProductOrderStatusHistory>(entity =>
        {
            entity.Property(x => x.Note).HasMaxLength(500);
            entity.HasOne(x => x.ProductOrder).WithMany(x => x.StatusHistory).HasForeignKey(x => x.ProductOrderId).OnDelete(DeleteBehavior.Cascade);
            entity.HasOne(x => x.ChangedByBusiness).WithMany().HasForeignKey(x => x.ChangedByBusinessId).OnDelete(DeleteBehavior.Restrict);
            entity.HasIndex(x => new { x.ProductOrderId, x.CreatedAt });
        });
    }

    private static void ConfigureDeliveries(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Delivery>(entity =>
        {
            entity.ToTable(table => table.HasCheckConstraint(
                "CK_Deliveries_ExactlyOneParent",
                "(\"MaterialTransactionId\" IS NOT NULL AND \"ProductOrderId\" IS NULL) OR (\"MaterialTransactionId\" IS NULL AND \"ProductOrderId\" IS NOT NULL)"));
            entity.Property(x => x.Location).HasMaxLength(500);
            entity.HasOne(x => x.MaterialTransaction).WithOne(x => x.Delivery).HasForeignKey<Delivery>(x => x.MaterialTransactionId).OnDelete(DeleteBehavior.Cascade);
            entity.HasOne(x => x.ProductOrder).WithOne(x => x.Delivery).HasForeignKey<Delivery>(x => x.ProductOrderId).OnDelete(DeleteBehavior.Cascade);
            entity.HasIndex(x => x.MaterialTransactionId).IsUnique();
            entity.HasIndex(x => x.ProductOrderId).IsUnique();
        });
    }
}
