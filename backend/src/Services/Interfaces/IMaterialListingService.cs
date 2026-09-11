using EcoLoop.Api.DTOs;

namespace EcoLoop.Api.Services.Interfaces;

public interface IMaterialListingService
{
    Task<object> GetAllAsync(
        string? search,
        string? category,
        int? type,
        int page,
        int pageSize);

    Task<MaterialListingDetailsDto?> GetByIdAsync(Guid id);
    Task<MaterialListingDetailsDto> CreateAsync(CreateMaterialListingRequest request);
    Task<MaterialListingDetailsDto?> UpdateAsync(Guid id, UpdateMaterialListingRequest request);
    Task<bool> ChangeStatusAsync(Guid id, int newStatus);
}
