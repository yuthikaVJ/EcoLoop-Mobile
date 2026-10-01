using EcoLoop.Api.DTOs;
using EcoLoop.Api.Models;
using EcoLoop.Api.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace EcoLoop.Api.Controllers;

// The acting/buyer business always comes from the JWT, never from the request body,
// and only the buyer or seller of an order can see or change it.
[ApiController]
[Authorize]
[Route("api/product-orders")]
public class ProductOrdersController : ControllerBase
{
    private readonly IProductOrderService _service;

    public ProductOrdersController(IProductOrderService service) => _service = service;

    [HttpPost]
    public async Task<IActionResult> Create(CreateProductOrderRequest request)
    {
        request.BuyerBusinessId = User.BusinessId();
        var result = await _service.CreateAsync(request);
        return result.Data == null
            ? BadRequest(new { message = result.Error })
            : CreatedAtAction(nameof(GetById), new { id = result.Data.Id }, result.Data);
    }

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> GetById(Guid id)
    {
        var item = await _service.GetByIdAsync(id);
        if (item == null) return NotFound(new { message = "Product order not found." });
        return IsParticipant(item) ? Ok(item) : Forbid();
    }

    [HttpGet("buyer/{businessId:guid}")]
    public async Task<IActionResult> GetBuyerHistory(Guid businessId, int page = 1, int pageSize = 20) =>
        businessId != User.BusinessId() ? Forbid() : Ok(await _service.GetBuyerHistoryAsync(businessId, page, pageSize));

    [HttpGet("seller/{businessId:guid}")]
    public async Task<IActionResult> GetSellerHistory(Guid businessId, int page = 1, int pageSize = 20) =>
        businessId != User.BusinessId() ? Forbid() : Ok(await _service.GetSellerHistoryAsync(businessId, page, pageSize));

    [HttpGet("{id:guid}/timeline")]
    public async Task<IActionResult> GetTimeline(Guid id)
    {
        var item = await _service.GetByIdAsync(id);
        if (item == null) return NotFound();
        return IsParticipant(item) ? Ok(item.StatusHistory) : Forbid();
    }

    [HttpGet("{id:guid}/delivery")]
    public async Task<IActionResult> GetDelivery(Guid id)
    {
        var item = await _service.GetByIdAsync(id);
        if (item == null) return NotFound();
        return IsParticipant(item) ? Ok(item.Delivery) : Forbid();
    }

    [HttpPut("{id:guid}/delivery")]
    public async Task<IActionResult> UpdateLocation(Guid id, UpdateDeliveryLocationRequest request)
    {
        request.ActingBusinessId = User.BusinessId();
        return Ok(await _service.UpdateLocationAsync(id, request));
    }

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

    private bool IsParticipant(ProductOrderDetailsDto item) =>
        User.BusinessId() is var me && (item.BuyerBusinessId == me || item.SellerBusinessId == me);

    private async Task<IActionResult> Change(Guid id, TransactionActionRequest request, ProductOrderStatus status)
    {
        if (request.Note?.Length > 500) return BadRequest(new { message = "Note must not exceed 500 characters." });
        if (await _service.GetByIdAsync(id) == null) return NotFound(new { message = "Record not found." });
        var result = await _service.ChangeStatusAsync(id, User.BusinessId(), status, request.Note);
        return result.Data == null ? BadRequest(new { message = result.Error }) : Ok(result.Data);
    }
}
