using EcoLoop.Api.DTOs;

namespace EcoLoop.Api.Services.Interfaces;

public interface IBusinessService
{
    Task<BusinessProfileDto?> GetProfileAsync(Guid businessId);
    Task<BusinessProfileDto?> UpdateProfileAsync(Guid businessId, UpdateBusinessProfileRequest request);
}
