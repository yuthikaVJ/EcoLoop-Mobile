using Npgsql;

namespace Backend.Tests.Database;

public class DeliveryTests : PostgreSqlFixture
{
    [Fact(DisplayName = "DB-10 DeliveryCanBeInsertedForProductOrder")]
    public async Task DeliveryCanBeInsertedForProductOrder()
    {
        await using var connection = CreateConnection();
        await connection.OpenAsync();

        var buyerBusinessId = Guid.NewGuid();
        var sellerBusinessId = Guid.NewGuid();
        var orderId = Guid.NewGuid();
        var deliveryId = Guid.NewGuid();
        var nowTicks = DateTime.UtcNow.Ticks;
        var createdAt = new DateTime(nowTicks - nowTicks % 10, DateTimeKind.Utc);
        var updatedAt = createdAt.AddMinutes(5);
        var locationUpdatedAt = createdAt.AddMinutes(4);

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
            orderCommand.Parameters.AddWithValue("status", 3);
            orderCommand.Parameters.AddWithValue("total_amount", 1500.00m);
            orderCommand.Parameters.AddWithValue("created_at", createdAt);
            orderCommand.Parameters.AddWithValue("updated_at", updatedAt);
            await orderCommand.ExecuteNonQueryAsync();
        }

        await using var deliveryCommand = new NpgsqlCommand(
            """
            INSERT INTO "Deliveries"
                ("Id", "MaterialTransactionId", "ProductOrderId", "Method",
                 "Location", "CreatedAt", "UpdatedAt", "Status",
                 "CurrentLatitude", "CurrentLongitude", "LocationUpdatedAt")
            VALUES
                (@id, @material_transaction_id, @product_order_id, @method,
                 @location, @created_at, @updated_at, @status,
                 @current_latitude, @current_longitude, @location_updated_at)
            """,
            connection);

        deliveryCommand.Parameters.AddWithValue("id", deliveryId);
        deliveryCommand.Parameters.AddWithValue("material_transaction_id", DBNull.Value);
        deliveryCommand.Parameters.AddWithValue("product_order_id", orderId);
        deliveryCommand.Parameters.AddWithValue("method", 1);
        deliveryCommand.Parameters.AddWithValue("location", "Colombo 07");
        deliveryCommand.Parameters.AddWithValue("created_at", createdAt);
        deliveryCommand.Parameters.AddWithValue("updated_at", updatedAt);
        deliveryCommand.Parameters.AddWithValue("status", 1);
        deliveryCommand.Parameters.AddWithValue("current_latitude", 6.9271);
        deliveryCommand.Parameters.AddWithValue("current_longitude", 79.8612);
        deliveryCommand.Parameters.AddWithValue("location_updated_at", locationUpdatedAt);

        var rowsAffected = await deliveryCommand.ExecuteNonQueryAsync();

        Assert.Equal(1, rowsAffected);

        await using var selectCommand = new NpgsqlCommand(
            """
            SELECT "MaterialTransactionId", "ProductOrderId", "Method", "Location",
                   "CreatedAt", "UpdatedAt", "Status", "CurrentLatitude",
                   "CurrentLongitude", "LocationUpdatedAt"
            FROM "Deliveries"
            WHERE "Id" = @id
            """,
            connection);

        selectCommand.Parameters.AddWithValue("id", deliveryId);

        await using var reader = await selectCommand.ExecuteReaderAsync();
        Assert.True(await reader.ReadAsync());
        Assert.True(reader.IsDBNull(0));
        Assert.Equal(orderId, reader.GetGuid(1));
        Assert.Equal(1, reader.GetInt32(2));
        Assert.Equal("Colombo 07", reader.GetString(3));
        Assert.Equal(createdAt, reader.GetFieldValue<DateTime>(4));
        Assert.Equal(updatedAt, reader.GetFieldValue<DateTime>(5));
        Assert.Equal(1, reader.GetInt32(6));
        Assert.Equal(6.9271, reader.GetDouble(7));
        Assert.Equal(79.8612, reader.GetDouble(8));
        Assert.Equal(locationUpdatedAt, reader.GetFieldValue<DateTime>(9));
    }
}
