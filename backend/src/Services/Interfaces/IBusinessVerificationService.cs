using EcoLoop.Api.DTOs;

namespace EcoLoop.Api.Services.Interfaces;

public interface IBusinessVerificationService
{
    Task<BusinessVerificationSummaryDto> GetSummaryAsync();
    Task<List<BusinessVerificationRequestDto>> GetRequestsAsync(string? status, string? search);
    Task<BusinessVerificationRequestDto> ApproveAsync(Guid businessId);
    Task<BusinessVerificationRequestDto> RejectAsync(Guid businessId, string reason);
}
