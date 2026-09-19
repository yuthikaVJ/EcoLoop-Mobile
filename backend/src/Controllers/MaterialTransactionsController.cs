using EcoLoop.Api.DTOs;
using EcoLoop.Api.Models;
using EcoLoop.Api.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace EcoLoop.Api.Controllers;

[ApiController]
[Route("api/material-transactions")]
public class MaterialTransactionsController : ControllerBase
{
    private readonly IMaterialTransactionService _service;

    public MaterialTransactionsController(IMaterialTransactionService service) => _service = service;

    [HttpPost]
    public async Task<IActionResult> Create(CreateMaterialTransactionRequest request)
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
        return item == null ? NotFound(new { message = "Material transaction not found." }) : Ok(item);
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

    [HttpPost("{id:guid}/accept")]
    public Task<IActionResult> Accept(Guid id, TransactionActionRequest request) => Change(id, request, MaterialTransactionStatus.Accepted);

    [HttpPost("{id:guid}/reject")]
    public Task<IActionResult> Reject(Guid id, TransactionActionRequest request) => Change(id, request, MaterialTransactionStatus.Rejected);

    [HttpPost("{id:guid}/processing")]
    public Task<IActionResult> Processing(Guid id, TransactionActionRequest request) => Change(id, request, MaterialTransactionStatus.Processing);

    [HttpPost("{id:guid}/ready")]
    public Task<IActionResult> Ready(Guid id, TransactionActionRequest request) => Change(id, request, MaterialTransactionStatus.Ready);

    [HttpPost("{id:guid}/complete")]
    public Task<IActionResult> Complete(Guid id, TransactionActionRequest request) => Change(id, request, MaterialTransactionStatus.Completed);

    [HttpPost("{id:guid}/cancel")]
    public Task<IActionResult> Cancel(Guid id, TransactionActionRequest request) => Change(id, request, MaterialTransactionStatus.Cancelled);

    private async Task<IActionResult> Change(Guid id, TransactionActionRequest request, MaterialTransactionStatus status)
    {
        var result = await _service.ChangeStatusAsync(id, request.ActingBusinessId, status, request.Note);
        return result.Data == null ? BadRequest(new { message = result.Error }) : Ok(result.Data);
    }
}
