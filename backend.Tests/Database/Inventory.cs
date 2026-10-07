using Npgsql;

namespace Backend.Tests.Database;

public class InventoryTests : PostgreSqlFixture
{
    [Fact(DisplayName = "DB-06 InventoryCanBeInserted")]
    public async Task InventoryCanBeInserted()
    {
        await using var connection = CreateConnection();
        await connection.OpenAsync();

        var businessId = Guid.NewGuid();
        var categoryId = Guid.NewGuid();
        var productId = Guid.NewGuid();
        var inventoryId = Guid.NewGuid();

        await using (var businessCommand = new NpgsqlCommand(
            """
            INSERT INTO "Businesses"
                ("Id", "BusinessName", "LogoUrl", "IsVerified")
            VALUES
                (@id, @business_name, @logo_url, @is_verified)
            """,
            connection))
        {
            businessCommand.Parameters.AddWithValue("id", businessId);
            businessCommand.Parameters.AddWithValue("business_name", "Green Inventory Co");
            businessCommand.Parameters.AddWithValue("logo_url", DBNull.Value);
            businessCommand.Parameters.AddWithValue("is_verified", true);
            await businessCommand.ExecuteNonQueryAsync();
        }

        await using (var categoryCommand = new NpgsqlCommand(
            """
            INSERT INTO "ProductCategories"
                ("Id", "Name", "Description", "IsActive")
            VALUES
                (@id, @name, @description, @is_active)
            """,
            connection))
        {
            categoryCommand.Parameters.AddWithValue("id", categoryId);
            categoryCommand.Parameters.AddWithValue("name", "Packaging");
            categoryCommand.Parameters.AddWithValue("description", "Packaging items");
            categoryCommand.Parameters.AddWithValue("is_active", true);
            await categoryCommand.ExecuteNonQueryAsync();
        }

        await using (var productCommand = new NpgsqlCommand(
            """
            INSERT INTO "Products"
                ("Id", "CategoryId", "BusinessId", "Name", "Description",
                 "MaterialType", "Price", "IsActive", "CreatedAt")
            VALUES
                (@id, @category_id, @business_id, @name, @description,
                 @material_type, @price, @is_active, @created_at)
            """,
            connection))
        {
            productCommand.Parameters.AddWithValue("id", productId);
            productCommand.Parameters.AddWithValue("category_id", categoryId);
            productCommand.Parameters.AddWithValue("business_id", businessId);
            productCommand.Parameters.AddWithValue("name", "Recycled Boxes");
            productCommand.Parameters.AddWithValue("description", "Bulk packaging boxes");
            productCommand.Parameters.AddWithValue("material_type", "Packaging");
            productCommand.Parameters.AddWithValue("price", 15.50m);
            productCommand.Parameters.AddWithValue("is_active", true);
            productCommand.Parameters.AddWithValue("created_at", DateTime.UtcNow);
            await productCommand.ExecuteNonQueryAsync();
        }

        await using var inventoryCommand = new NpgsqlCommand(
            """
            INSERT INTO "Inventories"
                ("Id", "ProductId", "Quantity", "IsAvailable")
            VALUES
                (@id, @product_id, @quantity, @is_available)
            """,
            connection);

        inventoryCommand.Parameters.AddWithValue("id", inventoryId);
        inventoryCommand.Parameters.AddWithValue("product_id", productId);
        inventoryCommand.Parameters.AddWithValue("quantity", 120);
        inventoryCommand.Parameters.AddWithValue("is_available", true);

        var rowsAffected = await inventoryCommand.ExecuteNonQueryAsync();

        Assert.Equal(1, rowsAffected);

        await using var selectCommand = new NpgsqlCommand(
            """
            SELECT "Quantity", "IsAvailable"
            FROM "Inventories"
            WHERE "Id" = @id
            """,
            connection);

        selectCommand.Parameters.AddWithValue("id", inventoryId);

        await using var reader = await selectCommand.ExecuteReaderAsync();
        Assert.True(await reader.ReadAsync());

        Assert.Equal(120, reader.GetInt32(0));
        Assert.True(reader.GetBoolean(1));
    }
}