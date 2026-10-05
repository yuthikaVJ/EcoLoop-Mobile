using EcoLoop.Api.DTOs;

namespace EcoLoop.Api.Services.Interfaces;

public interface IBusinessService
{
    Task<AccountProfileDto?> GetProfileAsync(Guid businessId);
    Task<AccountProfileDto?> UpdateProfileAsync(Guid businessId, UpdateAccountProfileRequest request);
}
