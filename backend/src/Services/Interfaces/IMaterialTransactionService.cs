using EcoLoop.Api.DTOs;
using EcoLoop.Api.Models;

namespace EcoLoop.Api.Services.Interfaces;

public interface IMaterialTransactionService
{
    Task<(MaterialTransactionDetailsDto? Data, string? Error)> CreateAsync(CreateMaterialTransactionRequest request);
    Task<MaterialTransactionDetailsDto?> GetByIdAsync(Guid id);
    Task<object> GetBuyerHistoryAsync(Guid buyerBusinessId, int page, int pageSize);
    Task<object> GetSellerHistoryAsync(Guid sellerBusinessId, int page, int pageSize);
    Task<(MaterialTransactionDetailsDto? Data, string? Error)> ChangeStatusAsync(Guid id, Guid actingBusinessId, MaterialTransactionStatus status, string? note);
}
