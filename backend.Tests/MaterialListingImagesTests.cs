using EcoLoop.Api.DTOs;
using EcoLoop.Api.Services;

namespace EcoLoop.Backend.Tests;

public class MaterialListingImagesTests
{
    [Fact]
    public async Task CreatedListing_KeepsEveryPhotoInOrder()
    {
        await using var context = await Component4TestContext.CreateAsync();
        var service = new MaterialListingService(context.Db);
        var photos = new List<string> { "/uploads/a.jpg", "/uploads/b.jpg", "/uploads/c.jpg" };

        var created = await service.CreateAsync(new CreateMaterialListingRequest
        {
            BusinessId = context.Seller.Id, Title = "Copper", Category = "METALS",
            Description = "Clean wire", Quantity = "500", Unit = "Kgs", Price = 35,
            PriceUnit = "Kg", Location = "Colombo", Type = 0,
            ImageUrl = photos[0], ImageUrls = photos,
        });

        Assert.Equal(photos, created.ImageUrls);
        Assert.Equal("/uploads/a.jpg", created.ImageUrl);
        var listed = Assert.Single(await service.GetByBusinessAsync(context.Seller.Id));
        Assert.Equal(photos, listed.ImageUrls);
    }

    [Fact]
    public async Task EditingPhotos_KeepsOnlyExistingOnes_AndAppendsNew()
    {
        await using var context = await Component4TestContext.CreateAsync();
        var service = new MaterialListingService(context.Db);
        var created = await service.CreateAsync(new CreateMaterialListingRequest
        {
            BusinessId = context.Seller.Id, Title = "Copper", Category = "METALS", Quantity = "5",
            Unit = "Kgs", Location = "Colombo", ImageUrl = "/a.jpg", ImageUrls = ["/a.jpg", "/b.jpg", "/c.jpg"],
        });

        // Keep c then a (new order); an injected URL that was never on the listing is ignored.
        var updated = await service.UpdateAsync(created.Id, new UpdateMaterialListingRequest
        {
            Title = "Copper", Category = "METALS", Quantity = "5", Unit = "Kgs", Location = "Colombo",
            KeepImageUrls = ["/c.jpg", "https://evil.example/x.jpg", "/a.jpg"],
        });
        Assert.Equal(["/c.jpg", "/a.jpg"], updated!.ImageUrls);
        Assert.Equal("/c.jpg", updated.ImageUrl);

        var withNew = await service.AddImagesAsync(created.Id, ["/d.jpg"]);
        Assert.Equal(["/c.jpg", "/a.jpg", "/d.jpg"], withNew!.ImageUrls);
        Assert.Equal(3, await service.ImageCountAsync(created.Id));

        // Leaving KeepImageUrls out doesn't touch the photos.
        var textOnly = await service.UpdateAsync(created.Id, new UpdateMaterialListingRequest
        {
            Title = "Copper wire", Category = "METALS", Quantity = "5", Unit = "Kgs", Location = "Colombo",
        });
        Assert.Equal(3, textOnly!.ImageUrls.Count);
    }

    [Theory]
    [InlineData("/uploads/material_listings/a.jpg", "/uploads/material_listings/a.jpg")]
    [InlineData("http://10.0.2.2:5252/uploads/material_listings/a.jpg", "/uploads/material_listings/a.jpg")]
    [InlineData("http://52.74.2.76:5252/uploads/material_listings/a.jpg", "/uploads/material_listings/a.jpg")]
    [InlineData("https://lh3.googleusercontent.com/photo.jpg", "https://lh3.googleusercontent.com/photo.jpg")]
    public void MediaPaths_KeepOnlyThePathOfOurUploads(string url, string expected) =>
        Assert.Equal(expected, MediaPaths.Normalize(url));

    [Fact]
    public async Task EditingFromAPhone_KeepsPhotosSentAsFullUrls()
    {
        await using var context = await Component4TestContext.CreateAsync();
        var service = new MaterialListingService(context.Db);
        var created = await service.CreateAsync(new CreateMaterialListingRequest
        {
            BusinessId = context.Seller.Id, Title = "Copper", Category = "METALS", Quantity = "5", Unit = "Kgs",
            Location = "Colombo", ImageUrl = "/uploads/material_listings/a.jpg",
            ImageUrls = ["/uploads/material_listings/a.jpg", "/uploads/material_listings/b.jpg"],
        });

        // The app shows (and sends back) full URLs with its own server address.
        var updated = await service.UpdateAsync(created.Id, new UpdateMaterialListingRequest
        {
            Title = "Copper", Category = "METALS", Quantity = "5", Unit = "Kgs", Location = "Colombo",
            KeepImageUrls = ["http://52.74.2.76:5252/uploads/material_listings/b.jpg"],
        });

        Assert.Equal(["/uploads/material_listings/b.jpg"], updated!.ImageUrls);
    }
}
