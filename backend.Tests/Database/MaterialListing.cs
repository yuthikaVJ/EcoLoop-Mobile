using Npgsql;

namespace Backend.Tests.Database;

public class MaterialListingTests : PostgreSqlFixture
{
    [Fact(DisplayName = "DB-04 MaterialListingCanBeInserted")]
    public async Task MaterialListingCanBeInserted()
    {
        await using var connection = CreateConnection();
        await connection.OpenAsync();

        var businessId = Guid.NewGuid();
        var listingId = Guid.NewGuid();
        var imageUrls = new[]
        {
            "https://example.com/material-1.jpg",
            "https://example.com/material-2.jpg"
        };

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
            command.Parameters.AddWithValue("business_name", "EcoLoop Test Business");
            command.Parameters.AddWithValue("logo_url", DBNull.Value);
            command.Parameters.AddWithValue("is_verified", true);
            await command.ExecuteNonQueryAsync();
        }

        await using var listingCommand = new NpgsqlCommand(
            """
            INSERT INTO "MaterialListings"
                ("Id", "BusinessId", "Title", "Category", "Description", "Quantity",
                 "Unit", "Location", "Price", "PriceUnit", "DeliveryMethod",
                 "SellerDeliveryAvailable", "Availability", "Condition",
                 "Type", "Status", "CreatedAt", "ImageUrl", "ImageUrls")
            VALUES
                (@id, @business_id, @title, @category, @description, @quantity,
                 @unit, @location, @price, @price_unit, @delivery_method,
                 @seller_delivery_available, @availability, @condition,
                 @type, @status, @created_at, @image_url, @image_urls)
            """,
            connection);

        listingCommand.Parameters.AddWithValue("id", listingId);
        listingCommand.Parameters.AddWithValue("business_id", businessId);
        listingCommand.Parameters.AddWithValue("title", "Recycled Plastic");
        listingCommand.Parameters.AddWithValue("category", "PLASTICS");
        listingCommand.Parameters.AddWithValue("description", "Clean recyclable plastic feedstock");
        listingCommand.Parameters.AddWithValue("quantity", "20");
        listingCommand.Parameters.AddWithValue("unit", "Kgs");
        listingCommand.Parameters.AddWithValue("location", "Colombo");
        listingCommand.Parameters.AddWithValue("price", 1200.00m);
        listingCommand.Parameters.AddWithValue("price_unit", "Kg");
        listingCommand.Parameters.AddWithValue("delivery_method", "Self Pickup");
        listingCommand.Parameters.AddWithValue("seller_delivery_available", true);
        listingCommand.Parameters.AddWithValue("availability", "Immediately");
        listingCommand.Parameters.AddWithValue("condition", "Clean, sorted");
        listingCommand.Parameters.AddWithValue("type", 0);
        listingCommand.Parameters.AddWithValue("status", 0);
        listingCommand.Parameters.AddWithValue("created_at", DateTime.UtcNow);
        listingCommand.Parameters.AddWithValue("image_url", "https://example.com/material-1.jpg");
        listingCommand.Parameters.AddWithValue("image_urls", imageUrls);

        var rowsAffected = await listingCommand.ExecuteNonQueryAsync();

        Assert.Equal(1, rowsAffected);

        await using var selectCommand = new NpgsqlCommand(
            """
            SELECT "Title", "Category", "Quantity", "ImageUrl", array_length("ImageUrls", 1)
            FROM "MaterialListings"
            WHERE "Id" = @id
            """,
            connection);

        selectCommand.Parameters.AddWithValue("id", listingId);

        await using var reader = await selectCommand.ExecuteReaderAsync();
        Assert.True(await reader.ReadAsync());

        Assert.Equal("Recycled Plastic", reader.GetString(0));
        Assert.Equal("PLASTICS", reader.GetString(1));
        Assert.Equal("20", reader.GetString(2));
        Assert.Equal("https://example.com/material-1.jpg", reader.GetString(3));
        Assert.Equal(2, reader.GetInt32(4));
    }
}
