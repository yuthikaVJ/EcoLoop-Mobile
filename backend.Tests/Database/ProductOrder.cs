using Npgsql;

namespace Backend.Tests.Database;

public class ProductOrderTests : PostgreSqlFixture
{
    [Fact(DisplayName = "DB-07 ProductOrderCanBeInserted")]
    public async Task ProductOrderCanBeInserted()
    {
        await using var connection = CreateConnection();
        await connection.OpenAsync();

        var buyerBusinessId = Guid.NewGuid();
        var sellerBusinessId = Guid.NewGuid();
        var orderId = Guid.NewGuid();

        await using (var buyerCommand = new NpgsqlCommand(
            """
            INSERT INTO "Businesses"
                ("Id", "BusinessName", "LogoUrl", "IsVerified")
            VALUES
                (@id, @business_name, @logo_url, @is_verified)
            """,
            connection))
        {
            buyerCommand.Parameters.AddWithValue("id", buyerBusinessId);
            buyerCommand.Parameters.AddWithValue("business_name", "Buyer Co");
            buyerCommand.Parameters.AddWithValue("logo_url", DBNull.Value);
            buyerCommand.Parameters.AddWithValue("is_verified", true);
            await buyerCommand.ExecuteNonQueryAsync();
        }

        await using (var sellerCommand = new NpgsqlCommand(
            """
            INSERT INTO "Businesses"
                ("Id", "BusinessName", "LogoUrl", "IsVerified")
            VALUES
                (@id, @business_name, @logo_url, @is_verified)
            """,
            connection))
        {
            sellerCommand.Parameters.AddWithValue("id", sellerBusinessId);
            sellerCommand.Parameters.AddWithValue("business_name", "Seller Co");
            sellerCommand.Parameters.AddWithValue("logo_url", DBNull.Value);
            sellerCommand.Parameters.AddWithValue("is_verified", true);
            await sellerCommand.ExecuteNonQueryAsync();
        }

        await using var orderCommand = new NpgsqlCommand(
            """
            INSERT INTO "ProductOrders"
                ("Id", "BuyerBusinessId", "SellerBusinessId", "Status",
                 "TotalAmount", "CreatedAt", "UpdatedAt")
            VALUES
                (@id, @buyer_business_id, @seller_business_id, @status,
                 @total_amount, @created_at, @updated_at)
            """,
            connection);

        orderCommand.Parameters.AddWithValue("id", orderId);
        orderCommand.Parameters.AddWithValue("buyer_business_id", buyerBusinessId);
        orderCommand.Parameters.AddWithValue("seller_business_id", sellerBusinessId);
        orderCommand.Parameters.AddWithValue("status", 0);
        orderCommand.Parameters.AddWithValue("total_amount", 2500.00m);
        orderCommand.Parameters.AddWithValue("created_at", DateTime.UtcNow);
        orderCommand.Parameters.AddWithValue("updated_at", DBNull.Value);

        var rowsAffected = await orderCommand.ExecuteNonQueryAsync();

        Assert.Equal(1, rowsAffected);

        await using var selectCommand = new NpgsqlCommand(
            """
            SELECT "Status", "TotalAmount", "BuyerBusinessId", "SellerBusinessId"
            FROM "ProductOrders"
            WHERE "Id" = @id
            """,
            connection);

        selectCommand.Parameters.AddWithValue("id", orderId);

        await using var reader = await selectCommand.ExecuteReaderAsync();
        Assert.True(await reader.ReadAsync());

        Assert.Equal(0, reader.GetInt32(0));
        Assert.Equal(2500.00m, reader.GetDecimal(1));
        Assert.Equal(buyerBusinessId, reader.GetGuid(2));
        Assert.Equal(sellerBusinessId, reader.GetGuid(3));
    }
}
