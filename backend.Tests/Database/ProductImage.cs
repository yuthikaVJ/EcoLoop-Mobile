using Npgsql;

namespace Backend.Tests.Database;

public class ProductImageTests : PostgreSqlFixture
{
    [Fact(DisplayName = "DB-05 ProductImageCanBeInserted")]
    public async Task ProductImageCanBeInserted()
    {
        await using var connection = CreateConnection();
        await connection.OpenAsync();

        var businessId = Guid.NewGuid();
        var categoryId = Guid.NewGuid();
        var productId = Guid.NewGuid();
        var imageId = Guid.NewGuid();

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
            businessCommand.Parameters.AddWithValue("business_name", "Green Goods Ltd");
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
            categoryCommand.Parameters.AddWithValue("name", "Electronics");
            categoryCommand.Parameters.AddWithValue("description", "Test category");
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
            productCommand.Parameters.AddWithValue("name", "Solar Panel");
            productCommand.Parameters.AddWithValue("description", "Reusable panel for demo");
            productCommand.Parameters.AddWithValue("material_type", "Electronics");
            productCommand.Parameters.AddWithValue("price", 280.00m);
            productCommand.Parameters.AddWithValue("is_active", true);
            productCommand.Parameters.AddWithValue("created_at", DateTime.UtcNow);
            await productCommand.ExecuteNonQueryAsync();
        }

        await using var imageCommand = new NpgsqlCommand(
            """
            INSERT INTO "ProductImages"
                ("Id", "ProductId", "ImageUrl", "IsPrimary", "DisplayOrder")
            VALUES
                (@id, @product_id, @image_url, @is_primary, @display_order)
            """,
            connection);

        imageCommand.Parameters.AddWithValue("id", imageId);
        imageCommand.Parameters.AddWithValue("product_id", productId);
        imageCommand.Parameters.AddWithValue("image_url", "https://example.com/images/solar-panel-main.jpg");
        imageCommand.Parameters.AddWithValue("is_primary", true);
        imageCommand.Parameters.AddWithValue("display_order", 1);

        var rowsAffected = await imageCommand.ExecuteNonQueryAsync();

        Assert.Equal(1, rowsAffected);

        await using var selectCommand = new NpgsqlCommand(
            """
            SELECT "ImageUrl", "IsPrimary", "DisplayOrder"
            FROM "ProductImages"
            WHERE "Id" = @id
            """,
            connection);

        selectCommand.Parameters.AddWithValue("id", imageId);

        await using var reader = await selectCommand.ExecuteReaderAsync();
        Assert.True(await reader.ReadAsync());

        Assert.Equal("https://example.com/images/solar-panel-main.jpg", reader.GetString(0));
        Assert.True(reader.GetBoolean(1));
        Assert.Equal(1, reader.GetInt32(2));
    }
}