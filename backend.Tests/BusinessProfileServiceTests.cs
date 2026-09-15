using System.Text;
using EcoLoop.Api.Data;
using EcoLoop.Api.DTOs;
using EcoLoop.Api.Services;
using Microsoft.EntityFrameworkCore;
using Xunit;

namespace backend.Tests;

public class BusinessProfileServiceTests
{
    private static EcoLoopDbContext CreateInMemoryDbContext()
    {
        var options = new DbContextOptionsBuilder<EcoLoopDbContext>()
            .UseInMemoryDatabase(databaseName: Guid.NewGuid().ToString())
            .Options;
        return new EcoLoopDbContext(options);
    }

    [Fact]
    public async Task CreateAsync_PersistsBioAndCoverPhoto_AndEnforcesOneProfilePerUser()
    {
        using var db = CreateInMemoryDbContext();
        var service = new BusinessProfileService(db);
        var userId = Guid.NewGuid();

        var request = new CreateBusinessProfileRequest
        {
            BusinessName = "Green Leaf Recycling",
            BusinessType = "Recycling Company",
            RegistrationNumber = "PV-12345",
            Bio = "Leading circular economy plastic recycler.",
            Description = "We process PET, HDPE, and PP plastics for sustainable manufacturing.",
            Email = "contact@greenleaf.lk",
            Phone = "+94112345678",
            Address = "Industrial Zone, Colombo",
            WebsiteUrl = "https://greenleaf.lk",
            LogoUrl = "https://greenleaf.lk/logo.png",
            CoverPhotoUrl = "https://greenleaf.lk/cover.jpg"
        };

        var result = await service.CreateAsync(request, userId);

        Assert.NotNull(result);
        Assert.Equal("Green Leaf Recycling", result.BusinessName);
        Assert.Equal("Leading circular economy plastic recycler.", result.Bio);
        Assert.Equal("https://greenleaf.lk/cover.jpg", result.CoverPhotoUrl);
        Assert.Equal(userId, result.UserId);

        // Attempting to create a second business profile for the same user must throw InvalidOperationException
        var secondRequest = new CreateBusinessProfileRequest
        {
            BusinessName = "Another Business",
            BusinessType = "Eco Manufacturer",
            RegistrationNumber = "PV-99999",
            Email = "second@greenleaf.lk",
            Phone = "+94112345679",
            Address = "Galle Road, Colombo"
        };

        await Assert.ThrowsAsync<InvalidOperationException>(
            () => service.CreateAsync(secondRequest, userId)
        );
    }

    [Fact]
    public async Task UpdateAsync_OwnerCanUpdateAllFields_Successfully()
    {
        using var db = CreateInMemoryDbContext();
        var service = new BusinessProfileService(db);
        var userId = Guid.NewGuid();

        var created = await service.CreateAsync(new CreateBusinessProfileRequest
        {
            BusinessName = "Old Name",
            BusinessType = "Recycling Company",
            RegistrationNumber = "REG-100",
            Email = "info@old.lk",
            Phone = "+94110000000",
            Address = "Old Address"
        }, userId);

        var updateRequest = new UpdateBusinessProfileRequest
        {
            BusinessName = "Updated Bio Energy Ltd",
            BusinessType = "Eco Manufacturer",
            Bio = "Pioneering zero-waste bio solutions.",
            Description = "Full cycle organic waste conversion.",
            Email = "hello@bioenergy.lk",
            Phone = "+94771234567",
            Address = "45 Green Way, Kandy",
            WebsiteUrl = "https://bioenergy.lk",
            LogoUrl = "https://bioenergy.lk/new-logo.png",
            CoverPhotoUrl = "https://bioenergy.lk/new-cover.jpg"
        };

        var updated = await service.UpdateAsync(created.Id, updateRequest, userId);

        Assert.Equal("Updated Bio Energy Ltd", updated.BusinessName);
        Assert.Equal("Eco Manufacturer", updated.BusinessType);
        Assert.Equal("Pioneering zero-waste bio solutions.", updated.Bio);
        Assert.Equal("hello@bioenergy.lk", updated.Email);
        Assert.Equal("https://bioenergy.lk/new-cover.jpg", updated.CoverPhotoUrl);
        Assert.NotNull(updated.UpdatedAt);
    }

    [Fact]
    public async Task UpdateAsync_NonOwner_ThrowsUnauthorizedAccessException()
    {
        using var db = CreateInMemoryDbContext();
        var service = new BusinessProfileService(db);
        var ownerUserId = Guid.NewGuid();
        var attackerUserId = Guid.NewGuid();

        var created = await service.CreateAsync(new CreateBusinessProfileRequest
        {
            BusinessName = "Protected Business",
            BusinessType = "Recycling Company",
            RegistrationNumber = "PROT-001",
            Email = "protected@business.lk",
            Phone = "+94112223334",
            Address = "Colombo 01"
        }, ownerUserId);

        var updateRequest = new UpdateBusinessProfileRequest
        {
            BusinessName = "Hacked Business",
            BusinessType = "Recycling Company",
            Email = "hacked@business.lk",
            Phone = "+94112223334",
            Address = "Colombo 01"
        };

        var ex = await Assert.ThrowsAsync<UnauthorizedAccessException>(
            () => service.UpdateAsync(created.Id, updateRequest, attackerUserId)
        );

        Assert.Contains("not authorized", ex.Message, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public async Task UploadImageAsync_RejectsInvalidFileType()
    {
        using var db = CreateInMemoryDbContext();
        var service = new BusinessProfileService(db);
        var userId = Guid.NewGuid();

        var created = await service.CreateAsync(new CreateBusinessProfileRequest
        {
            BusinessName = "Upload Test Business",
            BusinessType = "Recycling Company",
            RegistrationNumber = "UPL-001",
            Email = "upload@test.lk",
            Phone = "+94115555555",
            Address = "Kaduwela"
        }, userId);

        using var invalidStream = new MemoryStream(Encoding.UTF8.GetBytes("malicious script content"));

        var ex = await Assert.ThrowsAsync<ArgumentException>(
            () => service.UploadImageAsync(created.Id, invalidStream, "virus.exe", "application/x-msdownload", "profile", userId)
        );

        Assert.Contains("Invalid file type", ex.Message);
    }

    [Fact]
    public async Task UploadImageAsync_NonOwner_ThrowsUnauthorizedAccessException()
    {
        using var db = CreateInMemoryDbContext();
        var service = new BusinessProfileService(db);
        var ownerUserId = Guid.NewGuid();
        var otherUserId = Guid.NewGuid();

        var created = await service.CreateAsync(new CreateBusinessProfileRequest
        {
            BusinessName = "Secure Business",
            BusinessType = "Recycling Company",
            RegistrationNumber = "SEC-001",
            Email = "secure@business.lk",
            Phone = "+94114444444",
            Address = "Colombo"
        }, ownerUserId);

        using var stream = new MemoryStream(new byte[100]);

        await Assert.ThrowsAsync<UnauthorizedAccessException>(
            () => service.UploadImageAsync(created.Id, stream, "avatar.png", "image/png", "profile", otherUserId)
        );
    }

    [Fact]
    public async Task DeleteImageAsync_OwnerCanDeleteCoverAndProfilePicture()
    {
        using var db = CreateInMemoryDbContext();
        var service = new BusinessProfileService(db);
        var userId = Guid.NewGuid();

        var created = await service.CreateAsync(new CreateBusinessProfileRequest
        {
            BusinessName = "Media Business",
            BusinessType = "Recycling Company",
            RegistrationNumber = "MED-001",
            Email = "media@business.lk",
            Phone = "+94117777777",
            Address = "Colombo",
            LogoUrl = "https://example.com/logo.png",
            CoverPhotoUrl = "https://example.com/cover.jpg"
        }, userId);

        // Delete cover
        var afterCoverDelete = await service.DeleteImageAsync(created.Id, "cover", userId);
        Assert.Null(afterCoverDelete.CoverPhotoUrl);
        Assert.NotNull(afterCoverDelete.LogoUrl);

        // Delete profile picture
        var afterProfileDelete = await service.DeleteImageAsync(created.Id, "profile", userId);
        Assert.Null(afterProfileDelete.LogoUrl);
    }

    [Fact]
    public async Task DeleteImageAsync_NonOwner_ThrowsUnauthorizedAccessException()
    {
        using var db = CreateInMemoryDbContext();
        var service = new BusinessProfileService(db);
        var ownerUserId = Guid.NewGuid();
        var otherUserId = Guid.NewGuid();

        var created = await service.CreateAsync(new CreateBusinessProfileRequest
        {
            BusinessName = "Owner Business",
            BusinessType = "Recycling Company",
            RegistrationNumber = "OWN-001",
            Email = "owner@business.lk",
            Phone = "+94118888888",
            Address = "Colombo",
            LogoUrl = "https://example.com/logo.png"
        }, ownerUserId);

        await Assert.ThrowsAsync<UnauthorizedAccessException>(
            () => service.DeleteImageAsync(created.Id, "profile", otherUserId)
        );
    }
}
