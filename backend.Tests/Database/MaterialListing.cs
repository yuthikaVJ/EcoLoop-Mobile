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

    [Fact(DisplayName = "DB-09 MaterialListingOptionalFieldsCanBePersisted")]
    public async Task MaterialListingOptionalFieldsCanBePersisted()
    {
        await using var connection = CreateConnection();
        await connection.OpenAsync();

        var businessId = Guid.NewGuid();
        var postedAsBusinessId = Guid.NewGuid();
        var listingId = Guid.NewGuid();
        var nowTicks = DateTime.UtcNow.Ticks;
        var createdAt = new DateTime(nowTicks - nowTicks % 10, DateTimeKind.Utc);
        var updatedAt = createdAt.AddMinutes(5);

        await using (var command = new NpgsqlCommand(
            """
            INSERT INTO "Businesses"
                ("Id", "BusinessName", "LogoUrl", "IsVerified")
            VALUES
                (@business_id, @business_name, @logo_url, @is_verified),
                (@posted_as_business_id, @posted_as_business_name, @logo_url, @is_verified)
            """,
            connection))
        {
            command.Parameters.AddWithValue("business_id", businessId);
            command.Parameters.AddWithValue("business_name", "Listing Owner");
            command.Parameters.AddWithValue("posted_as_business_id", postedAsBusinessId);
            command.Parameters.AddWithValue("posted_as_business_name", "Verified Seller Hub");
            command.Parameters.AddWithValue("logo_url", DBNull.Value);
            command.Parameters.AddWithValue("is_verified", true);
            await command.ExecuteNonQueryAsync();
        }

        await using var listingCommand = new NpgsqlCommand(
            """
            INSERT INTO "MaterialListings"
                ("Id", "BusinessId", "PostedAsBusinessId", "Title", "Category",
                 "Description", "Quantity", "Unit", "Location", "Price",
                 "PriceUnit", "DeliveryMethod", "SellerDeliveryAvailable",
                 "Availability", "Condition", "Type", "Status", "CreatedAt",
                 "UpdatedAt", "ImageUrl", "ImageUrls")
            VALUES
                (@id, @business_id, @posted_as_business_id, @title, @category,
                 @description, @quantity, @unit, @location, @price,
                 @price_unit, @delivery_method, @seller_delivery_available,
                 @availability, @condition, @type, @status, @created_at,
                 @updated_at, @image_url, @image_urls)
            """,
            connection);

        listingCommand.Parameters.AddWithValue("id", listingId);
        listingCommand.Parameters.AddWithValue("business_id", businessId);
        listingCommand.Parameters.AddWithValue("posted_as_business_id", postedAsBusinessId);
        listingCommand.Parameters.AddWithValue("title", "Reusable Containers");
        listingCommand.Parameters.AddWithValue("category", "PLASTICS");
        listingCommand.Parameters.AddWithValue("description", string.Empty);
        listingCommand.Parameters.AddWithValue("quantity", "50");
        listingCommand.Parameters.AddWithValue("unit", "Units");
        listingCommand.Parameters.AddWithValue("location", "Kandy");
        listingCommand.Parameters.AddWithValue("price", 75.00m);
        listingCommand.Parameters.AddWithValue("price_unit", "Unit");
        listingCommand.Parameters.AddWithValue("delivery_method", "Seller Delivery");
        listingCommand.Parameters.AddWithValue("seller_delivery_available", true);
        listingCommand.Parameters.AddWithValue("availability", DBNull.Value);
        listingCommand.Parameters.AddWithValue("condition", "Clean");
        listingCommand.Parameters.AddWithValue("type", 1);
        listingCommand.Parameters.AddWithValue("status", 1);
        listingCommand.Parameters.AddWithValue("created_at", createdAt);
        listingCommand.Parameters.AddWithValue("updated_at", updatedAt);
        listingCommand.Parameters.AddWithValue("image_url", DBNull.Value);
        listingCommand.Parameters.AddWithValue("image_urls", Array.Empty<string>());

        var rowsAffected = await listingCommand.ExecuteNonQueryAsync();

        Assert.Equal(1, rowsAffected);

        await using var selectCommand = new NpgsqlCommand(
            """
            SELECT "BusinessId", "PostedAsBusinessId", "Description", "Availability",
                   "Type", "Status", "UpdatedAt", "ImageUrl",
                   array_length("ImageUrls", 1)
            FROM "MaterialListings"
            WHERE "Id" = @id
            """,
            connection);

        selectCommand.Parameters.AddWithValue("id", listingId);

        await using var reader = await selectCommand.ExecuteReaderAsync();
        Assert.True(await reader.ReadAsync());
        Assert.Equal(businessId, reader.GetGuid(0));
        Assert.Equal(postedAsBusinessId, reader.GetGuid(1));
        Assert.Equal(string.Empty, reader.GetString(2));
        Assert.True(reader.IsDBNull(3));
        Assert.Equal(1, reader.GetInt32(4));
        Assert.Equal(1, reader.GetInt32(5));
        Assert.Equal(updatedAt, reader.GetFieldValue<DateTime>(6));
        Assert.True(reader.IsDBNull(7));
        Assert.True(reader.IsDBNull(8));
    }
}
