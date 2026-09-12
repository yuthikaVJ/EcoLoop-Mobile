using EcoLoop.Api.DTOs;
using EcoLoop.Api.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace EcoLoop.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class MaterialListingsController : ControllerBase
{
    private readonly IMaterialListingService _listingService;

    public MaterialListingsController(IMaterialListingService listingService)
    {
        _listingService = listingService;
    }

    [HttpGet]
    public async Task<IActionResult> GetAll(
        [FromQuery] string? search,
        [FromQuery] string? category,
        [FromQuery] int? type,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 10)
    {
        var result = await _listingService.GetAllAsync(search, category, type, page, pageSize);
        return Ok(result);
    }

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> GetById(Guid id)
    {
        var listing = await _listingService.GetByIdAsync(id);
        
        if (listing == null)
            return NotFound(new { message = "Listing not found or is no longer active." });

        return Ok(listing);
    }

    [HttpPost]
    public async Task<IActionResult> Create([FromForm] CreateMaterialListingRequest request, IFormFile? image)
    {
        if (image != null && image.Length > 0)
        {
            var uploadsFolder = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", "uploads", "material_listings");
            if (!Directory.Exists(uploadsFolder))
                Directory.CreateDirectory(uploadsFolder);

            var uniqueFileName = Guid.NewGuid().ToString() + "_" + image.FileName;
            var filePath = Path.Combine(uploadsFolder, uniqueFileName);

            using (var fileStream = new FileStream(filePath, FileMode.Create))
            {
                await image.CopyToAsync(fileStream);
            }

            request.ImageUrl = $"http://10.0.2.2:5252/uploads/material_listings/{uniqueFileName}";
        }

        var listing = await _listingService.CreateAsync(request);
        return CreatedAtAction(nameof(GetById), new { id = listing.Id }, listing);
    }

    [HttpPut("{id:guid}")]
    public async Task<IActionResult> Update(Guid id, [FromBody] UpdateMaterialListingRequest request)
    {
        var listing = await _listingService.UpdateAsync(id, request);
        
        if (listing == null)
            return NotFound(new { message = "Listing not found or is no longer active." });

        return Ok(listing);
    }

    // Changing status allows us to Mark as Sold (1) or Delete (2)
    [HttpPatch("{id:guid}/status")]
    public async Task<IActionResult> ChangeStatus(Guid id, [FromBody] int newStatus)
    {
        var success = await _listingService.ChangeStatusAsync(id, newStatus);
        
        if (!success)
            return BadRequest(new { message = "Failed to update status. Listing may not exist or status is invalid." });

        return NoContent();
    }
}
