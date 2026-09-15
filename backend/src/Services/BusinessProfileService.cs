using EcoLoop.Api.Data;
using EcoLoop.Api.DTOs;
using EcoLoop.Api.Models;
using EcoLoop.Api.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace EcoLoop.Api.Services;

public class BusinessProfileService : IBusinessProfileService
{
    private readonly EcoLoopDbContext _db;

    public BusinessProfileService(EcoLoopDbContext db)
    {
        _db = db;
    }

    public async Task<BusinessProfileDto> CreateAsync(
        CreateBusinessProfileRequest request,
        Guid? userId = null)
    {
        var normalizedRegNum = request.RegistrationNumber.Trim();
        var exists = await _db.Businesses
            .AnyAsync(b => b.RegistrationNumber.ToLower() == normalizedRegNum.ToLower());

        if (exists)
        {
            throw new InvalidOperationException($"A business with registration number '{normalizedRegNum}' already exists.");
        }

        var effectiveUserId = userId ?? request.UserId;
        if (effectiveUserId.HasValue)
        {
            var userHasProfile = await _db.Businesses
                .AnyAsync(b => b.UserId == effectiveUserId.Value);

            if (userHasProfile)
            {
                throw new InvalidOperationException("User already has an associated business profile.");
            }
        }

        var business = new Business
        {
            Id = Guid.NewGuid(),
            BusinessName = request.BusinessName.Trim(),
            BusinessType = request.BusinessType.Trim(),
            RegistrationNumber = normalizedRegNum,
            Description = string.IsNullOrWhiteSpace(request.Description) ? null : request.Description.Trim(),
            Email = request.Email.Trim().ToLowerInvariant(),
            Phone = request.Phone.Trim(),
            Address = request.Address.Trim(),
            WebsiteUrl = string.IsNullOrWhiteSpace(request.WebsiteUrl) ? null : request.WebsiteUrl.Trim(),
            LogoUrl = string.IsNullOrWhiteSpace(request.LogoUrl) ? null : request.LogoUrl.Trim(),
            IsVerified = false,
            Status = "Unverified",
            UserId = effectiveUserId,
            CreatedAt = DateTime.UtcNow
        };

        _db.Businesses.Add(business);
        await _db.SaveChangesAsync();

        return MapToDto(business);
    }

    public async Task<BusinessProfileDto?> GetByIdAsync(Guid id)
    {
        var business = await _db.Businesses
            .AsNoTracking()
            .FirstOrDefaultAsync(b => b.Id == id);

        return business == null ? null : MapToDto(business);
    }

    public async Task<BusinessProfileDto?> GetByUserIdAsync(Guid userId)
    {
        var business = await _db.Businesses
            .AsNoTracking()
            .FirstOrDefaultAsync(b => b.UserId == userId);

        return business == null ? null : MapToDto(business);
    }

    public async Task<List<BusinessProfileDto>> GetAllAsync()
    {
        return await _db.Businesses
            .AsNoTracking()
            .OrderByDescending(b => b.CreatedAt)
            .Select(b => MapToDto(b))
            .ToListAsync();
    }

    private static BusinessProfileDto MapToDto(Business b)
    {
        return new BusinessProfileDto
        {
            Id = b.Id,
            BusinessName = b.BusinessName,
            BusinessType = b.BusinessType,
            RegistrationNumber = b.RegistrationNumber,
            Description = b.Description,
            Email = b.Email,
            Phone = b.Phone,
            Address = b.Address,
            WebsiteUrl = b.WebsiteUrl,
            LogoUrl = b.LogoUrl,
            IsVerified = b.IsVerified,
            Status = b.Status,
            UserId = b.UserId,
            CreatedAt = b.CreatedAt,
            UpdatedAt = b.UpdatedAt
        };
    }
}
