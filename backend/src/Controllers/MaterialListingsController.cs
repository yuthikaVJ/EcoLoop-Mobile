using EcoLoop.Api.DTOs;
using EcoLoop.Api.Services.Interfaces;
using EcoLoop.Api.Services.Matching;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace EcoLoop.Api.Controllers;

[Authorize]
[ApiController]
[Route("api/[controller]")]
public class MaterialListingsController : ControllerBase
{
    private readonly IMaterialListingService _listingService;
    private readonly IBusinessProfileService _businessProfiles;
    private readonly MatchingService _matching;
    private readonly ILogger<MaterialListingsController> _logger;

    public MaterialListingsController(
        IMaterialListingService listingService,
        IBusinessProfileService businessProfiles,
        MatchingService matching,
        ILogger<MaterialListingsController> logger)
    {
        _listingService = listingService;
        _businessProfiles = businessProfiles;
        _matching = matching;
        _logger = logger;
    }

    [HttpGet]
    public async Task<IActionResult> GetAll(
        [FromQuery] string? search,
        [FromQuery] string? category,
        [FromQuery] int? type,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 10,
        [FromQuery] Guid? businessId = null,
        [FromQuery] int status = 0)
    {
        if (status != 0 && (status != 1 || !businessId.HasValue))
            return BadRequest(new { message = "Completed listings require a business ID." });
        var result = await _listingService.GetAllAsync(search, category, type, page, pageSize, businessId, status);
        return Ok(result);
    }

    [HttpGet("business/{businessId:guid}")]
    public async Task<IActionResult> GetByBusiness(Guid businessId)
    {
        var items = await _listingService.GetByBusinessAsync(businessId);
        return Ok(new { items });
    }

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> GetById(Guid id)
    {
        var listing = await _listingService.GetByIdAsync(id);
        
        if (listing == null)
            return NotFound(new { message = "Listing not found or is no longer active." });

        return Ok(listing);
    }

    private const int MaxImages = 10;
    private const long MaxImageBytes = 10 * 1024 * 1024;
    private static readonly HashSet<string> ImageExtensions =
        new(StringComparer.OrdinalIgnoreCase) { ".jpg", ".jpeg", ".png", ".webp", ".heic" };

    // Photos arrive as repeated "images" form fields; "image" is the older single-photo field.
    [HttpPost]
    public async Task<IActionResult> Create(
        [FromForm] CreateMaterialListingRequest request,
        IFormFile? image,
        [FromForm] List<IFormFile>? images)
    {
        if (request.PostedAsBusinessId.HasValue)
        {
            try
            {
                await _businessProfiles.EnsureCanPostAsAsync(User.BusinessId(), request.PostedAsBusinessId.Value);
            }
            catch (UnauthorizedAccessException ex)
            {
                return StatusCode(StatusCodes.Status403Forbidden, new { message = ex.Message });
            }
            catch (InvalidOperationException ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        var files = (images ?? []).Where(f => f.Length > 0).ToList();
        if (image != null && image.Length > 0) files.Insert(0, image);

        var (urls, photoError) = await SavePhotosAsync(files, existingCount: 0);
        if (photoError != null) return BadRequest(new { message = photoError });
        request.ImageUrls = urls;
        request.ImageUrl = urls.FirstOrDefault();

        // Extract BusinessId from JWT claims
        var businessIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (Guid.TryParse(businessIdClaim, out var businessId))
        {
            request.BusinessId = businessId;
        }
        else
        {
            return Unauthorized(new { message = "Invalid token or Business ID missing." });
        }

        var listing = await _listingService.CreateAsync(request);
        await StartMatchingAsync(listing.Id, businessId);
        return CreatedAtAction(nameof(GetById), new { id = listing.Id }, listing);
    }

    [HttpPut("{id:guid}")]
    public async Task<IActionResult> Update(Guid id, [FromBody] UpdateMaterialListingRequest request)
    {
        if (await _listingService.GetOwnerIdAsync(id) is { } owner && owner != User.BusinessId())
            return StatusCode(StatusCodes.Status403Forbidden, new { message = "You can only edit your own listings." });

        var listing = await _listingService.UpdateAsync(id, request);

        if (listing == null)
            return NotFound(new { message = "Listing not found or is no longer active." });

        // Edited details can change which posts match.
        await StartMatchingAsync(id, User.BusinessId());
        return Ok(listing);
    }

    // Adds photos to an existing listing (the edit page); removing photos goes
    // through Update with KeepImageUrls.
    [HttpPost("{id:guid}/images")]
    public async Task<IActionResult> AddImages(Guid id, [FromForm] List<IFormFile>? images)
    {
        if (await _listingService.GetOwnerIdAsync(id) is not { } owner)
            return NotFound(new { message = "Listing not found." });
        if (owner != User.BusinessId())
            return StatusCode(StatusCodes.Status403Forbidden, new { message = "You can only edit your own listings." });
        if (await _listingService.ImageCountAsync(id) is not { } existing)
            return NotFound(new { message = "Listing not found or is no longer active." });

        var files = (images ?? []).Where(f => f.Length > 0).ToList();
        if (files.Count == 0)
            return BadRequest(new { message = "Choose at least one photo." });
        var (urls, photoError) = await SavePhotosAsync(files, existing);
        if (photoError != null) return BadRequest(new { message = photoError });

        var listing = await _listingService.AddImagesAsync(id, urls);
        return listing == null ? NotFound(new { message = "Listing not found or is no longer active." }) : Ok(listing);
    }

    // Changing status allows us to Mark as Sold (1) or Delete (2)
    [HttpPatch("{id:guid}/status")]
    public async Task<IActionResult> ChangeStatus(Guid id, [FromBody] int newStatus)
    {
        if (await _listingService.GetOwnerIdAsync(id) is { } owner && owner != User.BusinessId())
            return StatusCode(StatusCodes.Status403Forbidden, new { message = "You can only change your own listings." });

        var success = await _listingService.ChangeStatusAsync(id, newStatus);
        
        if (!success)
            return BadRequest(new { message = "Failed to update status. Listing may not exist or status is invalid." });

        return NoContent();
    }

    // Validates every file first, then saves them under random names.
    private static async Task<(List<string> Urls, string? Error)> SavePhotosAsync(List<IFormFile> files, int existingCount)
    {
        if (existingCount + files.Count > MaxImages)
            return ([], $"A listing can have at most {MaxImages} photos.");
        foreach (var file in files)
        {
            if (!ImageExtensions.Contains(Path.GetExtension(file.FileName)))
                return ([], "Photos must be JPG, PNG, WEBP or HEIC images.");
            if (file.Length > MaxImageBytes)
                return ([], "Each photo must be smaller than 10 MB.");
        }

        var urls = new List<string>();
        if (files.Count == 0) return (urls, null);
        var uploadsFolder = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", "uploads", "material_listings");
        Directory.CreateDirectory(uploadsFolder);
        foreach (var file in files)
        {
            // Never trust the client's file name in a path: keep only its extension.
            var fileName = $"{Guid.NewGuid():N}{Path.GetExtension(file.FileName).ToLowerInvariant()}";
            await using (var stream = new FileStream(Path.Combine(uploadsFolder, fileName), FileMode.CreateNew))
            {
                await file.CopyToAsync(stream);
            }
            // Relative path: each client adds its own server address (see MediaPaths).
            urls.Add($"/uploads/material_listings/{fileName}");
        }
        return (urls, null);
    }

    // Matching is best-effort: a problem with the AI must never block posting.
    private async Task StartMatchingAsync(Guid listingId, Guid ownerId)
    {
        try
        {
            await _matching.StartAsync(listingId, ownerId);
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Could not start AI matching for listing {ListingId}.", listingId);
        }
    }
}
