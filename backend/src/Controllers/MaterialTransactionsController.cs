using EcoLoop.Api.DTOs;
using EcoLoop.Api.Models;
using EcoLoop.Api.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace EcoLoop.Api.Controllers;

// The acting/buyer business always comes from the JWT, never from the request body,
// and only the buyer or seller of a transaction can see or change it.
[ApiController]
[Authorize]
[Route("api/material-transactions")]
public class MaterialTransactionsController : ControllerBase
{
    private readonly IMaterialTransactionService _service;
    private readonly IMaterialListingService _listings;

    public MaterialTransactionsController(IMaterialTransactionService service, IMaterialListingService listings)
    {
        _service = service;
        _listings = listings;
    }

    [HttpPost]
    public async Task<IActionResult> Create(CreateMaterialTransactionRequest request)
    {
        // The signed-in business must be the one answering the listing: the buyer of an
        // "I Have" listing or the supplier (seller) of an "I Need" listing, never its owner.
        var me = User.BusinessId();
        var listing = await _listings.GetByIdAsync(request.MaterialListingId);
        if (listing == null) return BadRequest(new { message = "Material listing was not found or is not active." });
        if (listing.BusinessId == me)
            return BadRequest(new { message = "You cannot start a transaction on your own listing." });
        if (request.BuyerBusinessId != me && request.SellerBusinessId != me) return Forbid();
        var result = await _service.CreateAsync(request);
        return result.Data == null
            ? BadRequest(new { message = result.Error })
            : CreatedAtAction(nameof(GetById), new { id = result.Data.Id }, result.Data);
    }

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> GetById(Guid id)
    {
        var item = await _service.GetByIdAsync(id);
        if (item == null) return NotFound(new { message = "Material transaction not found." });
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

    [HttpPut("{id:guid}")]
    public async Task<IActionResult> UpdateDetails(Guid id, UpdateMaterialTransactionRequest request)
    {
        request.ActingBusinessId = User.BusinessId();
        return Ok(await _service.UpdateDetailsAsync(id, request));
    }

    [HttpPut("{id:guid}/delivery")]
    public async Task<IActionResult> UpdateLocation(Guid id, UpdateDeliveryLocationRequest request)
    {
        request.ActingBusinessId = User.BusinessId();
        return Ok(await _service.UpdateLocationAsync(id, request));
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

    private bool IsParticipant(MaterialTransactionDetailsDto item) =>
        User.BusinessId() is var me && (item.BuyerBusinessId == me || item.SellerBusinessId == me);

    private async Task<IActionResult> Change(Guid id, TransactionActionRequest request, MaterialTransactionStatus status)
    {
        if (request.Note?.Length > 500) return BadRequest(new { message = "Note must not exceed 500 characters." });
        if (await _service.GetByIdAsync(id) == null) return NotFound(new { message = "Record not found." });
        var result = await _service.ChangeStatusAsync(id, User.BusinessId(), status, request.Note);
        return result.Data == null ? BadRequest(new { message = result.Error }) : Ok(result.Data);
    }
}
