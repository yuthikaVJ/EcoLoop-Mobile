using EcoLoop.Api.DTOs;
using EcoLoop.Api.Models;

namespace EcoLoop.Api.Services.Interfaces;

public interface IProductOrderService
{
    Task<ProductOrderDetailsDto> UpdateLocationAsync(Guid id, UpdateDeliveryLocationRequest request);
    Task<(ProductOrderDetailsDto? Data, string? Error)> CreateAsync(CreateProductOrderRequest request);
    Task<ProductOrderDetailsDto?> GetByIdAsync(Guid id);
    Task<object> GetBuyerHistoryAsync(Guid buyerBusinessId, int page, int pageSize);
    Task<object> GetSellerHistoryAsync(Guid sellerBusinessId, int page, int pageSize);
    Task<(ProductOrderDetailsDto? Data, string? Error)> ChangeStatusAsync(Guid id, Guid actingBusinessId, ProductOrderStatus status, string? note);
}
