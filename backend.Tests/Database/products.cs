using Npgsql;

namespace Backend.Tests.Database;

public class ProductTests : PostgreSqlFixture
{
    [Fact(DisplayName = "DB-02 ProductInsertionTest")]
    public async Task ProductCanBeInserted()
    {
        await using var connection = CreateConnection();
        await connection.OpenAsync();

        var businessId = Guid.NewGuid();
        var categoryId = Guid.NewGuid();
        var productId = Guid.NewGuid();

        await using (var command = new NpgsqlCommand(
            """
            INSERT INTO "Businesses"
                ("Id", "BusinessName", "LogoUrl", "IsVerified")
            VALUES
                (@id, @business_name, @logo_url, @is_verified)
            """,
            connection))
        {
            command.Parameters.AddWithValue("id", businessId);
            command.Parameters.AddWithValue("business_name", "Test Business");
            command.Parameters.AddWithValue("logo_url", DBNull.Value);
            command.Parameters.AddWithValue("is_verified", true);
            await command.ExecuteNonQueryAsync();
        }

        await using (var command = new NpgsqlCommand(
            """
            INSERT INTO "ProductCategories"
                ("Id", "Name", "Description", "IsActive")
            VALUES
                (@id, @name, @description, @is_active)
            """,
            connection))
        {
            command.Parameters.AddWithValue("id", categoryId);
            command.Parameters.AddWithValue("name", "Electronics");
            command.Parameters.AddWithValue("description", "Test category");
            command.Parameters.AddWithValue("is_active", true);
            await command.ExecuteNonQueryAsync();
        }

        await using var productCommand = new NpgsqlCommand(
            """
            INSERT INTO "Products"
                ("Id", "CategoryId", "BusinessId", "Name", "Description",
                 "MaterialType", "Price", "IsActive", "CreatedAt")
            VALUES
                (@id, @category_id, @business_id, @name, @description,
                 @material_type, @price, @is_active, @created_at)
            """,
            connection);

        productCommand.Parameters.AddWithValue("id", productId);
        productCommand.Parameters.AddWithValue("category_id", categoryId);
        productCommand.Parameters.AddWithValue("business_id", businessId);
        productCommand.Parameters.AddWithValue("name", "Recycled Laptop");
        productCommand.Parameters.AddWithValue("description", "Test product");
        productCommand.Parameters.AddWithValue("material_type", "Electronics");
        productCommand.Parameters.AddWithValue("price", 125.50m);
        productCommand.Parameters.AddWithValue("is_active", true);
        productCommand.Parameters.AddWithValue("created_at", DateTime.UtcNow);

        var rowsAffected = await productCommand.ExecuteNonQueryAsync();

        Assert.Equal(1, rowsAffected);
    }
}
