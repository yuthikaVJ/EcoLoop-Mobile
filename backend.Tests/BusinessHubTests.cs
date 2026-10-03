using EcoLoop.Api.DTOs;
using EcoLoop.Api.Models;
using EcoLoop.Api.Services;

namespace EcoLoop.Backend.Tests;

public class BusinessHubTests
{
    private static async Task<Business> AddHubProfileAsync(Component4TestContext context, Guid ownerId, string name = "GreenCycle")
    {
        var profile = new Business
        {
            BusinessName = name,
            IndustryType = "Recycling Company",
            RegistrationNumber = $"REG-{Guid.NewGuid():N}",
            Email = "green@ecoloop.lk",
            PhoneNumber = "0771234567",
            Address = "Colombo",
            UserId = ownerId,
        };
        context.Db.Businesses.Add(profile);
        await context.Db.SaveChangesAsync();
        return profile;
    }

    [Fact]
    public async Task NewProfile_IsPendingAndCannotBePostedAs()
    {
        await using var context = await Component4TestContext.CreateAsync();
        var profiles = new BusinessProfileService(context.Db);
        var created = await profiles.CreateAsync(new CreateBusinessProfileRequest
        {
            BusinessName = "GreenCycle", BusinessType = "Recycling Company", RegistrationNumber = "PV-1",
            Email = "green@ecoloop.lk", Phone = "0771234567", Address = "Colombo"
        }, context.Seller.Id);

        Assert.Equal(BusinessVerificationStatus.Unverified, created.Status);
        await Assert.ThrowsAsync<InvalidOperationException>(
            () => profiles.EnsureCanPostAsAsync(context.Seller.Id, created.Id));
    }

    [Fact]
    public async Task Approve_LetsOwnerPostAs_ButNobodyElse()
    {
        await using var context = await Component4TestContext.CreateAsync();
        var profile = await AddHubProfileAsync(context, context.Seller.Id);
        var approved = await new BusinessVerificationService(context.Db).ApproveAsync(profile.Id);

        Assert.True(approved.IsVerified);
        Assert.Equal(BusinessVerificationStatus.Verified, approved.Status);
        Assert.Equal("Seller", approved.OwnerName);

        var profiles = new BusinessProfileService(context.Db);
        await profiles.EnsureCanPostAsAsync(context.Seller.Id, profile.Id);
        await Assert.ThrowsAsync<UnauthorizedAccessException>(
            () => profiles.EnsureCanPostAsAsync(context.Buyer.Id, profile.Id));
    }

    [Fact]
    public async Task Reject_StoresReason_AndEditingResubmits()
    {
        await using var context = await Component4TestContext.CreateAsync();
        var profile = await AddHubProfileAsync(context, context.Seller.Id);
        var verifications = new BusinessVerificationService(context.Db);

        var rejected = await verifications.RejectAsync(profile.Id, "Registration number does not match eROC.");
        Assert.Equal(BusinessVerificationStatus.Rejected, rejected.Status);
        Assert.Equal("Registration number does not match eROC.", rejected.VerificationNote);
        Assert.Equal(1, (await verifications.GetSummaryAsync()).Rejected);

        var updated = await new BusinessProfileService(context.Db).UpdateAsync(profile.Id, new UpdateBusinessProfileRequest
        {
            BusinessName = "GreenCycle", BusinessType = "Recycling Company",
            Email = "green@ecoloop.lk", Phone = "0771234567", Address = "Colombo"
        }, context.Seller.Id);

        Assert.Equal(BusinessVerificationStatus.Unverified, updated.Status);
        Assert.Null(updated.VerificationNote);
        Assert.Single(await verifications.GetRequestsAsync(BusinessVerificationStatus.Unverified, null));
    }

    [Fact]
    public async Task AccountRows_AreNotVerificationRequests()
    {
        await using var context = await Component4TestContext.CreateAsync();
        await AddHubProfileAsync(context, context.Seller.Id);

        var all = await new BusinessVerificationService(context.Db).GetRequestsAsync("all", null);

        Assert.Single(all);
        await Assert.ThrowsAsync<KeyNotFoundException>(
            () => new BusinessVerificationService(context.Db).ApproveAsync(context.Buyer.Id));
    }

    [Fact]
    public async Task ListingPostedAsBusiness_ShowsBusinessAsSeller_AndAppearsInItsPosts()
    {
        await using var context = await Component4TestContext.CreateAsync();
        var profile = await AddHubProfileAsync(context, context.Seller.Id);
        await new BusinessVerificationService(context.Db).ApproveAsync(profile.Id);

        var listing = await new MaterialListingService(context.Db).CreateAsync(new CreateMaterialListingRequest
        {
            BusinessId = context.Seller.Id, PostedAsBusinessId = profile.Id, Title = "PET bottles",
            Category = "PLASTICS", Description = "Baled", Quantity = "500", Unit = "Kgs",
            Price = 10, PriceUnit = "Kg", Location = "Colombo", Type = 0
        });

        // The account still owns it (transactions/chat), the business is displayed.
        Assert.Equal(context.Seller.Id, listing.BusinessId);
        Assert.Equal("GreenCycle", listing.Seller);
        Assert.True(listing.SellerIsVerified);

        var product = await context.AddProductAsync();
        product.PostedAsBusinessId = profile.Id;
        await context.Db.SaveChangesAsync();
        Assert.Equal("GreenCycle", (await new ProductService(context.Db).GetByIdAsync(product.Id))!.Seller);

        var posts = await new BusinessProfileService(context.Db).GetPostsByBusinessIdAsync(profile.Id);
        Assert.Equal(2, posts.Count);
        Assert.Contains(posts, p => p.Type == "I HAVE" && p.Title == "PET bottles" && p.Quantity == "500 Kgs");
        Assert.Contains(posts, p => p.Type == "PRODUCT" && p.Title == "Reusable Bottle");
    }
}
