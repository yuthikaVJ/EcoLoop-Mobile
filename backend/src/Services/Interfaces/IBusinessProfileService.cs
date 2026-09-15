using EcoLoop.Api.DTOs;

namespace EcoLoop.Api.Services.Interfaces;

public interface IBusinessProfileService
{
    Task<BusinessProfileDto> CreateAsync(CreateBusinessProfileRequest request, Guid? userId = null);
    Task<BusinessProfileDto?> GetByIdAsync(Guid id);
    Task<BusinessProfileDto?> GetByUserIdAsync(Guid userId);
    Task<List<BusinessProfileDto>> GetAllAsync();
}
