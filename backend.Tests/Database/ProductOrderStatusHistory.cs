using Npgsql;

namespace Backend.Tests.Database;

public class ProductOrderStatusHistoryTests : PostgreSqlFixture
{
    [Fact(DisplayName = "DB-08 ProductOrderStatusHistoryCanBeInserted")]
    public async Task ProductOrderStatusHistoryCanBeInserted()
    {
        await using var connection = CreateConnection();
        await connection.OpenAsync();

        var buyerBusinessId = Guid.NewGuid();
        var sellerBusinessId = Guid.NewGuid();
        var orderId = Guid.NewGuid();
        var historyId = Guid.NewGuid();
        var nowTicks = DateTime.UtcNow.Ticks;
        var createdAt = new DateTime(nowTicks - nowTicks % 10, DateTimeKind.Utc);

        await using (var businessCommand = new NpgsqlCommand(
            """
            INSERT INTO "Businesses"
                ("Id", "BusinessName", "LogoUrl", "IsVerified")
            VALUES
                (@buyer_id, @buyer_name, @logo_url, @is_verified),
                (@seller_id, @seller_name, @logo_url, @is_verified)
            """,
            connection))
        {
            businessCommand.Parameters.AddWithValue("buyer_id", buyerBusinessId);
            businessCommand.Parameters.AddWithValue("buyer_name", "Buyer Co");
            businessCommand.Parameters.AddWithValue("seller_id", sellerBusinessId);
            businessCommand.Parameters.AddWithValue("seller_name", "Seller Co");
            businessCommand.Parameters.AddWithValue("logo_url", DBNull.Value);
            businessCommand.Parameters.AddWithValue("is_verified", true);
            await businessCommand.ExecuteNonQueryAsync();
        }

        await using (var orderCommand = new NpgsqlCommand(
            """
            INSERT INTO "ProductOrders"
                ("Id", "BuyerBusinessId", "SellerBusinessId", "Status",
                 "TotalAmount", "CreatedAt", "UpdatedAt")
            VALUES
                (@id, @buyer_business_id, @seller_business_id, @status,
                 @total_amount, @created_at, @updated_at)
            """,
            connection))
        {
            orderCommand.Parameters.AddWithValue("id", orderId);
            orderCommand.Parameters.AddWithValue("buyer_business_id", buyerBusinessId);
            orderCommand.Parameters.AddWithValue("seller_business_id", sellerBusinessId);
            orderCommand.Parameters.AddWithValue("status", 0);
            orderCommand.Parameters.AddWithValue("total_amount", 2500.00m);
            orderCommand.Parameters.AddWithValue("created_at", createdAt);
            orderCommand.Parameters.AddWithValue("updated_at", DBNull.Value);
            await orderCommand.ExecuteNonQueryAsync();
        }

        await using var historyCommand = new NpgsqlCommand(
            """
            INSERT INTO "ProductOrderStatusHistories"
                ("Id", "ProductOrderId", "Status", "ChangedByBusinessId",
                 "Note", "CreatedAt")
            VALUES
                (@id, @product_order_id, @status, @changed_by_business_id,
                 @note, @created_at)
            """,
            connection);

        historyCommand.Parameters.AddWithValue("id", historyId);
        historyCommand.Parameters.AddWithValue("product_order_id", orderId);
        historyCommand.Parameters.AddWithValue("status", 1);
        historyCommand.Parameters.AddWithValue("changed_by_business_id", sellerBusinessId);
        historyCommand.Parameters.AddWithValue("note", "Order confirmed");
        historyCommand.Parameters.AddWithValue("created_at", createdAt);

        var rowsAffected = await historyCommand.ExecuteNonQueryAsync();

        Assert.Equal(1, rowsAffected);

        await using var selectCommand = new NpgsqlCommand(
            """
            SELECT "ProductOrderId", "Status", "ChangedByBusinessId", "Note", "CreatedAt"
            FROM "ProductOrderStatusHistories"
            WHERE "Id" = @id
            """,
            connection);

        selectCommand.Parameters.AddWithValue("id", historyId);

        await using var reader = await selectCommand.ExecuteReaderAsync();
        Assert.True(await reader.ReadAsync());
        Assert.Equal(orderId, reader.GetGuid(0));
        Assert.Equal(1, reader.GetInt32(1));
        Assert.Equal(sellerBusinessId, reader.GetGuid(2));
        Assert.Equal("Order confirmed", reader.GetString(3));
        Assert.Equal(createdAt, reader.GetFieldValue<DateTime>(4));
    }
}
