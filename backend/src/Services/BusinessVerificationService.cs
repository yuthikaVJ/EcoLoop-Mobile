using EcoLoop.Api.Data;
using EcoLoop.Api.DTOs;
using EcoLoop.Api.Models;
using EcoLoop.Api.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace EcoLoop.Api.Services;

// Admin review of Business Hub profiles (eROC verification).
public class BusinessVerificationService : IBusinessVerificationService
{
    private readonly EcoLoopDbContext _db;
    private readonly NotificationService? _notifications;

    public BusinessVerificationService(EcoLoopDbContext db, NotificationService? notifications = null)
    {
        _db = db;
        _notifications = notifications;
    }

    public async Task<BusinessVerificationSummaryDto> GetSummaryAsync()
    {
        var counts = await HubProfiles()
            .GroupBy(b => b.Status)
            .Select(g => new { Status = g.Key, Count = g.Count() })
            .ToListAsync();

        int CountOf(string status) => counts.FirstOrDefault(c => c.Status == status)?.Count ?? 0;

        return new BusinessVerificationSummaryDto
        {
            Pending = CountOf(BusinessVerificationStatus.Unverified),
            Verified = CountOf(BusinessVerificationStatus.Verified),
            Rejected = CountOf(BusinessVerificationStatus.Rejected),
        };
    }

    public async Task<List<BusinessVerificationRequestDto>> GetRequestsAsync(string? status, string? search)
    {
        var query = HubProfiles().AsNoTracking();

        if (!string.IsNullOrWhiteSpace(status) && !status.Equals("all", StringComparison.OrdinalIgnoreCase))
        {
            query = query.Where(b => b.Status == status);
        }

        if (!string.IsNullOrWhiteSpace(search))
        {
            var text = search.Trim().ToLower();
            query = query.Where(b =>
                b.BusinessName.ToLower().Contains(text) ||
                (b.RegistrationNumber != null && b.RegistrationNumber.ToLower().Contains(text)) ||
                (b.Email != null && b.Email.ToLower().Contains(text)));
        }

        // Oldest requests first, so nobody waits forever.
        var businesses = await query.OrderBy(b => b.CreatedAt).ToListAsync();
        var owners = await LoadOwnersAsync(businesses);
        return businesses.Select(b => ToDto(b, owners)).ToList();
    }

    public async Task<BusinessVerificationRequestDto> ApproveAsync(Guid businessId)
    {
        var business = await FindAsync(businessId);
        business.Status = BusinessVerificationStatus.Verified;
        business.IsVerified = true;
        business.VerificationNote = null;
        business.VerifiedAt = DateTime.UtcNow;
        business.UpdatedAt = DateTime.UtcNow;
        await _db.SaveChangesAsync();

        await NotifyOwnerAsync(business,
            "Business verified",
            $"{business.BusinessName} is now verified. You can post listings and products as this business.");

        return ToDto(business, await LoadOwnersAsync([business]));
    }

    public async Task<BusinessVerificationRequestDto> RejectAsync(Guid businessId, string reason)
    {
        var business = await FindAsync(businessId);
        business.Status = BusinessVerificationStatus.Rejected;
        business.IsVerified = false;
        business.VerificationNote = reason.Trim();
        business.VerifiedAt = null;
        business.UpdatedAt = DateTime.UtcNow;
        await _db.SaveChangesAsync();

        await NotifyOwnerAsync(business,
            "Business verification rejected",
            $"{business.BusinessName}: {business.VerificationNote}");

        return ToDto(business, await LoadOwnersAsync([business]));
    }

    private IQueryable<Business> HubProfiles() => _db.Businesses.Where(b => b.UserId != null);

    private async Task<Business> FindAsync(Guid id) =>
        await HubProfiles().FirstOrDefaultAsync(b => b.Id == id)
        ?? throw new KeyNotFoundException($"Business profile with ID '{id}' was not found.");

    private async Task<Dictionary<Guid, Business>> LoadOwnersAsync(List<Business> businesses)
    {
        var ownerIds = businesses
            .Where(b => b.UserId.HasValue)
            .Select(b => b.UserId!.Value)
            .Distinct()
            .ToList();

        return await _db.Businesses.AsNoTracking()
            .Where(b => ownerIds.Contains(b.Id))
            .ToDictionaryAsync(b => b.Id);
    }

    private async Task NotifyOwnerAsync(Business business, string title, string body)
    {
        if (_notifications == null || business.UserId == null) return;

        var tokens = await _db.DeviceTokens
            .Where(d => d.BusinessId == business.UserId.Value)
            .Select(d => d.Token)
            .ToListAsync();

        await _notifications.SendPushNotificationAsync(tokens, title, body,
            new Dictionary<string, string>
            {
                ["type"] = "business_verification",
                ["businessId"] = business.Id.ToString(),
            });
    }

    private static BusinessVerificationRequestDto ToDto(Business b, Dictionary<Guid, Business> owners)
    {
        var owner = b.UserId.HasValue && owners.TryGetValue(b.UserId.Value, out var o) ? o : null;
        return new BusinessVerificationRequestDto
        {
            Id = b.Id,
            BusinessName = b.BusinessName,
            BusinessType = b.IndustryType ?? string.Empty,
            RegistrationNumber = b.RegistrationNumber ?? string.Empty,
            Bio = b.Bio,
            Description = b.Description,
            Email = b.Email ?? string.Empty,
            Phone = b.PhoneNumber ?? string.Empty,
            Address = b.Address ?? string.Empty,
            WebsiteUrl = b.WebsiteUrl,
            LogoUrl = b.LogoUrl,
            CoverPhotoUrl = b.CoverPhotoUrl,
            IsVerified = b.IsVerified,
            Status = b.Status,
            VerificationNote = b.VerificationNote,
            VerifiedAt = b.VerifiedAt,
            UserId = b.UserId,
            CreatedAt = b.CreatedAt,
            UpdatedAt = b.UpdatedAt,
            OwnerName = owner?.BusinessName,
            OwnerEmail = owner?.Email,
        };
    }
}
