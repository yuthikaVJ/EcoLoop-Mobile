using EcoLoop.Api.DTOs;

namespace EcoLoop.Api.Services.Interfaces;

public interface IBusinessProfileService
{
    Task<BusinessProfileDto> CreateAsync(CreateBusinessProfileRequest request, Guid? userId = null);
    Task<BusinessProfileDto?> GetByIdAsync(Guid id);
    Task<BusinessProfileDto?> GetByUserIdAsync(Guid userId);
    Task<List<BusinessProfileDto>> GetAllAsync();
    Task<BusinessProfileDto> UpdateAsync(Guid id, UpdateBusinessProfileRequest request, Guid? userId = null);
    Task<BusinessProfileDto> UploadImageAsync(Guid id, Stream fileStream, string fileName, string contentType, string imageType, Guid? userId = null);
    Task<BusinessProfileDto> DeleteImageAsync(Guid id, string imageType, Guid? userId = null);
}
