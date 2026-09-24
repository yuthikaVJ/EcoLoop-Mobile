using EcoLoop.Api.DTOs;
using EcoLoop.Api.Models;
using EcoLoop.Api.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace EcoLoop.Api.Controllers;

[ApiController]
[Route("api/product-orders")]
public class ProductOrdersController : ControllerBase
{
    private readonly IProductOrderService _service;

    public ProductOrdersController(IProductOrderService service) => _service = service;

    [HttpPost]
    public async Task<IActionResult> Create(CreateProductOrderRequest request)
    {
        var result = await _service.CreateAsync(request);
        return result.Data == null
            ? BadRequest(new { message = result.Error })
            : CreatedAtAction(nameof(GetById), new { id = result.Data.Id }, result.Data);
    }

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> GetById(Guid id)
    {
        var item = await _service.GetByIdAsync(id);
        return item == null ? NotFound(new { message = "Product order not found." }) : Ok(item);
    }

    [HttpGet("buyer/{businessId:guid}")]
    public async Task<IActionResult> GetBuyerHistory(Guid businessId, int page = 1, int pageSize = 20) =>
        Ok(await _service.GetBuyerHistoryAsync(businessId, page, pageSize));

    [HttpGet("seller/{businessId:guid}")]
    public async Task<IActionResult> GetSellerHistory(Guid businessId, int page = 1, int pageSize = 20) =>
        Ok(await _service.GetSellerHistoryAsync(businessId, page, pageSize));

    [HttpGet("{id:guid}/timeline")]
    public async Task<IActionResult> GetTimeline(Guid id)
    {
        var item = await _service.GetByIdAsync(id);
        return item == null ? NotFound() : Ok(item.StatusHistory);
    }

    [HttpGet("{id:guid}/delivery")]
    public async Task<IActionResult> GetDelivery(Guid id)
    {
        var item = await _service.GetByIdAsync(id);
        return item == null ? NotFound() : Ok(item.Delivery);
    }

    [HttpPut("{id:guid}/delivery")]
    public async Task<IActionResult> UpdateLocation(Guid id, UpdateDeliveryLocationRequest request) =>
        Ok(await _service.UpdateLocationAsync(id, request));

    [HttpPost("{id:guid}/confirm")]
    public Task<IActionResult> Confirm(Guid id, TransactionActionRequest request) => Change(id, request, ProductOrderStatus.Confirmed);

    [HttpPost("{id:guid}/processing")]
    public Task<IActionResult> Processing(Guid id, TransactionActionRequest request) => Change(id, request, ProductOrderStatus.Processing);

    [HttpPost("{id:guid}/ready")]
    public Task<IActionResult> Ready(Guid id, TransactionActionRequest request) => Change(id, request, ProductOrderStatus.Ready);

    [HttpPost("{id:guid}/complete")]
    public Task<IActionResult> Complete(Guid id, TransactionActionRequest request) => Change(id, request, ProductOrderStatus.Completed);

    [HttpPost("{id:guid}/deliver")]
    public Task<IActionResult> Deliver(Guid id, TransactionActionRequest request) => Change(id, request, ProductOrderStatus.Delivered);

    [HttpPost("{id:guid}/cancel")]
    public Task<IActionResult> Cancel(Guid id, TransactionActionRequest request) => Change(id, request, ProductOrderStatus.Cancelled);

    private async Task<IActionResult> Change(Guid id, TransactionActionRequest request, ProductOrderStatus status)
    {
        if (request.Note?.Length > 500) return BadRequest(new { message = "Note must not exceed 500 characters." });
        if (await _service.GetByIdAsync(id) == null) return NotFound(new { message = "Record not found." });
        var result = await _service.ChangeStatusAsync(id, request.ActingBusinessId, status, request.Note);
        return result.Data == null ? BadRequest(new { message = result.Error }) : Ok(result.Data);
    }
}
