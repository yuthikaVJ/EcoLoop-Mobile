using Npgsql;
using Xunit;

namespace Backend.Tests.Database;

public class ProductCategoryTests : PostgreSqlFixture
{
    [Fact(DisplayName = "DB-03 ProductCategoryCanBeInserted")]
    public async Task ProductCategoryCanBeInserted()
    {
        await using var connection = CreateConnection();

        await connection.OpenAsync();

        var categoryId = Guid.NewGuid();

        await using var command = new NpgsqlCommand(
            """
            INSERT INTO "ProductCategories"
                ("Id", "Name", "Description", "IsActive")
            VALUES
                (@id, @name, @description, @is_active)
            """,
            connection);

        command.Parameters.AddWithValue("id", categoryId);
        command.Parameters.AddWithValue("name", "Electronics");
        command.Parameters.AddWithValue(
            "description",
            "Electronic products");
        command.Parameters.AddWithValue("is_active", true);

        var rowsAffected = await command.ExecuteNonQueryAsync();

        Assert.Equal(1, rowsAffected);
    }
}