using EcoLoop.Api.Data;
using EcoLoop.Api.DTOs;
using EcoLoop.Api.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace EcoLoop.Api.Services;

public class BusinessService : IBusinessService
{
    private readonly EcoLoopDbContext _context;

    public BusinessService(EcoLoopDbContext context)
    {
        _context = context;
    }

    public async Task<BusinessProfileDto?> GetProfileAsync(Guid businessId)
    {
        var business = await _context.Businesses.FindAsync(businessId);
        if (business == null) return null;

        return new BusinessProfileDto
        {
            Id = business.Id,
            BusinessName = business.BusinessName,
            Email = business.Email,
            LogoUrl = business.LogoUrl,
            PhoneNumber = business.PhoneNumber,
            Address = business.Address,
            IndustryType = business.IndustryType,
            Description = business.Description,
            CreatedAt = business.CreatedAt,
            IsVerified = business.IsVerified
        };
    }

    public async Task<BusinessProfileDto?> UpdateProfileAsync(Guid businessId, UpdateBusinessProfileRequest request)
    {
        var business = await _context.Businesses.FindAsync(businessId);
        if (business == null) return null;

        business.BusinessName = request.BusinessName;
        business.PhoneNumber = request.PhoneNumber;
        business.Address = request.Address;
        business.IndustryType = request.IndustryType;
        business.Description = request.Description;

        await _context.SaveChangesAsync();

        return await GetProfileAsync(businessId);
    }
}
