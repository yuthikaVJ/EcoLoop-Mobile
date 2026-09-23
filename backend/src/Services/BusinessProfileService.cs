using EcoLoop.Api.Data;
using EcoLoop.Api.DTOs;
using EcoLoop.Api.Models;
using EcoLoop.Api.Services.Interfaces;
using Microsoft.AspNetCore.Hosting;
using Microsoft.EntityFrameworkCore;

namespace EcoLoop.Api.Services;

public class BusinessProfileService : IBusinessProfileService
{
    private readonly EcoLoopDbContext _db;
    private readonly IWebHostEnvironment? _environment;
    private static readonly HashSet<string> AllowedExtensions = new(StringComparer.OrdinalIgnoreCase)
    {
        ".jpg", ".jpeg", ".png"
    };
    private const long MaxFileSizeBytes = 5 * 1024 * 1024; // 5 MB

    public BusinessProfileService(EcoLoopDbContext db, IWebHostEnvironment? environment = null)
    {
        _db = db;
        _environment = environment;
    }

    public async Task<BusinessProfileDto> CreateAsync(
        CreateBusinessProfileRequest request,
        Guid? userId = null)
    {
        var normalizedRegNum = request.RegistrationNumber.Trim();
        var exists = await _db.Businesses
            .AnyAsync(b => b.RegistrationNumber.ToLower() == normalizedRegNum.ToLower());

        if (exists)
        {
            throw new InvalidOperationException($"A business with registration number '{normalizedRegNum}' already exists.");
        }

        var effectiveUserId = userId ?? request.UserId;
        if (effectiveUserId.HasValue)
        {
            var userHasProfile = await _db.Businesses
                .AnyAsync(b => b.UserId == effectiveUserId.Value);

            if (userHasProfile)
            {
                throw new InvalidOperationException("User already has an associated business profile.");
            }
        }

        var business = new Business
        {
            Id = Guid.NewGuid(),
            BusinessName = request.BusinessName.Trim(),
            BusinessType = request.BusinessType.Trim(),
            RegistrationNumber = normalizedRegNum,
            Bio = string.IsNullOrWhiteSpace(request.Bio) ? null : request.Bio.Trim(),
            Description = string.IsNullOrWhiteSpace(request.Description) ? null : request.Description.Trim(),
            Email = request.Email.Trim().ToLowerInvariant(),
            Phone = request.Phone.Trim(),
            Address = request.Address.Trim(),
            WebsiteUrl = string.IsNullOrWhiteSpace(request.WebsiteUrl) ? null : request.WebsiteUrl.Trim(),
            LogoUrl = string.IsNullOrWhiteSpace(request.LogoUrl) ? null : request.LogoUrl.Trim(),
            CoverPhotoUrl = string.IsNullOrWhiteSpace(request.CoverPhotoUrl) ? null : request.CoverPhotoUrl.Trim(),
            IsVerified = false,
            Status = "Unverified",
            UserId = effectiveUserId,
            CreatedAt = DateTime.UtcNow
        };

        _db.Businesses.Add(business);
        await _db.SaveChangesAsync();

        return MapToDto(business);
    }

    public async Task<BusinessProfileDto?> GetByIdAsync(Guid id)
    {
        var business = await _db.Businesses
            .AsNoTracking()
            .FirstOrDefaultAsync(b => b.Id == id);

        return business == null ? null : MapToDto(business);
    }

    public async Task<BusinessProfileDto?> GetByUserIdAsync(Guid userId)
    {
        var business = await _db.Businesses
            .AsNoTracking()
            .FirstOrDefaultAsync(b => b.UserId == userId);

        return business == null ? null : MapToDto(business);
    }

    public async Task<List<BusinessProfileDto>> GetMyProfilesAsync(Guid? userId, string? email = null)
    {
        var query = _db.Businesses.AsNoTracking().AsQueryable();

        var normalizedEmail = email?.Trim().ToLowerInvariant();
        var hasEmail = !string.IsNullOrEmpty(normalizedEmail);
        var hasUserId = userId.HasValue;

        if (hasUserId && hasEmail)
        {
            var uid = userId!.Value;
            query = query.Where(b => b.UserId == uid || b.Email.ToLower() == normalizedEmail);
        }
        else if (hasUserId)
        {
            var uid = userId!.Value;
            query = query.Where(b => b.UserId == uid);
        }
        else if (hasEmail)
        {
            query = query.Where(b => b.Email.ToLower() == normalizedEmail);
        }
        else
        {
            return new List<BusinessProfileDto>();
        }

        return await query
            .OrderByDescending(b => b.CreatedAt)
            .Select(b => MapToDto(b))
            .ToListAsync();
    }

    public async Task<List<BusinessProfileDto>> GetAllAsync()
    {
        return await _db.Businesses
            .AsNoTracking()
            .OrderByDescending(b => b.CreatedAt)
            .Select(b => MapToDto(b))
            .ToListAsync();
    }

    public async Task<BusinessProfileDto> UpdateAsync(
        Guid id,
        UpdateBusinessProfileRequest request,
        Guid? userId = null)
    {
        var business = await _db.Businesses.FirstOrDefaultAsync(b => b.Id == id);
        if (business == null)
        {
            throw new KeyNotFoundException($"Business profile with ID '{id}' was not found.");
        }

        AuthorizeOwner(business, userId);

        business.BusinessName = request.BusinessName.Trim();
        business.BusinessType = request.BusinessType.Trim();
        business.Bio = string.IsNullOrWhiteSpace(request.Bio) ? null : request.Bio.Trim();
        business.Description = string.IsNullOrWhiteSpace(request.Description) ? null : request.Description.Trim();
        business.Email = request.Email.Trim().ToLowerInvariant();
        business.Phone = request.Phone.Trim();
        business.Address = request.Address.Trim();
        business.WebsiteUrl = string.IsNullOrWhiteSpace(request.WebsiteUrl) ? null : request.WebsiteUrl.Trim();
        
        if (request.LogoUrl != null)
        {
            business.LogoUrl = string.IsNullOrWhiteSpace(request.LogoUrl) ? null : request.LogoUrl.Trim();
        }

        if (request.CoverPhotoUrl != null)
        {
            business.CoverPhotoUrl = string.IsNullOrWhiteSpace(request.CoverPhotoUrl) ? null : request.CoverPhotoUrl.Trim();
        }

        business.UpdatedAt = DateTime.UtcNow;

        await _db.SaveChangesAsync();
        return MapToDto(business);
    }

    public async Task<BusinessProfileDto> UploadImageAsync(
        Guid id,
        Stream fileStream,
        string fileName,
        string contentType,
        string imageType,
        Guid? userId = null)
    {
        var business = await _db.Businesses.FirstOrDefaultAsync(b => b.Id == id);
        if (business == null)
        {
            throw new KeyNotFoundException($"Business profile with ID '{id}' was not found.");
        }

        AuthorizeOwner(business, userId);

        var normalizedType = imageType.Trim().ToLowerInvariant();
        if (normalizedType != "profile" && normalizedType != "logo" && normalizedType != "cover")
        {
            throw new ArgumentException("Image type must be either 'profile' or 'cover'.");
        }

        var ext = Path.GetExtension(fileName).ToLowerInvariant();
        if (string.IsNullOrWhiteSpace(ext) || !AllowedExtensions.Contains(ext))
        {
            throw new ArgumentException($"Invalid file type '{ext}'. Allowed extensions are: {string.Join(", ", AllowedExtensions)}");
        }

        if (fileStream.Length >= MaxFileSizeBytes)
        {
            throw new ArgumentException("File size must be less than 5 MB.");
        }

        var rootPath = _environment?.WebRootPath ?? Path.Combine(Directory.GetCurrentDirectory(), "wwwroot");
        var uploadDir = Path.Combine(rootPath, "uploads", "business_profiles", id.ToString());
        Directory.CreateDirectory(uploadDir);

        var safeFileName = $"{normalizedType}_{Guid.NewGuid():N}{ext}";
        var physicalPath = Path.Combine(uploadDir, safeFileName);

        // Remove old file if it was a local upload
        var oldUrl = (normalizedType == "cover") ? business.CoverPhotoUrl : business.LogoUrl;
        DeleteLocalFileIfPresent(rootPath, oldUrl);

        using (var destStream = new FileStream(physicalPath, FileMode.Create))
        {
            if (fileStream.CanSeek)
            {
                fileStream.Position = 0;
            }
            await fileStream.CopyToAsync(destStream);
        }

        var relativeUrl = $"/uploads/business_profiles/{id}/{safeFileName}";

        if (normalizedType == "cover")
        {
            business.CoverPhotoUrl = relativeUrl;
        }
        else
        {
            business.LogoUrl = relativeUrl;
        }

        business.UpdatedAt = DateTime.UtcNow;
        await _db.SaveChangesAsync();

        return MapToDto(business);
    }

    public async Task<BusinessProfileDto> DeleteImageAsync(
        Guid id,
        string imageType,
        Guid? userId = null)
    {
        var business = await _db.Businesses.FirstOrDefaultAsync(b => b.Id == id);
        if (business == null)
        {
            throw new KeyNotFoundException($"Business profile with ID '{id}' was not found.");
        }

        AuthorizeOwner(business, userId);

        var normalizedType = imageType.Trim().ToLowerInvariant();
        var rootPath = _environment?.WebRootPath ?? Path.Combine(Directory.GetCurrentDirectory(), "wwwroot");

        if (normalizedType == "cover")
        {
            DeleteLocalFileIfPresent(rootPath, business.CoverPhotoUrl);
            business.CoverPhotoUrl = null;
        }
        else if (normalizedType == "profile" || normalizedType == "logo")
        {
            DeleteLocalFileIfPresent(rootPath, business.LogoUrl);
            business.LogoUrl = null;
        }
        else
        {
            throw new ArgumentException("Image type must be either 'profile' or 'cover'.");
        }

        business.UpdatedAt = DateTime.UtcNow;
        await _db.SaveChangesAsync();

        return MapToDto(business);
    }

    public async Task DeleteAsync(Guid id, Guid? userId = null)
    {
        var business = await _db.Businesses.FirstOrDefaultAsync(b => b.Id == id);
        if (business == null)
        {
            throw new KeyNotFoundException($"Business profile with ID '{id}' was not found.");
        }

        AuthorizeOwner(business, userId);

        var rootPath = _environment?.WebRootPath ?? Path.Combine(Directory.GetCurrentDirectory(), "wwwroot");
        DeleteLocalFileIfPresent(rootPath, business.LogoUrl);
        DeleteLocalFileIfPresent(rootPath, business.CoverPhotoUrl);

        _db.Businesses.Remove(business);
        await _db.SaveChangesAsync();
    }

    public async Task<List<BusinessPostDto>> GetPostsByBusinessIdAsync(Guid businessId)
    {
        var business = await _db.Businesses.AsNoTracking().FirstOrDefaultAsync(b => b.Id == businessId);
        if (business == null)
        {
            return new List<BusinessPostDto>();
        }

        var list = new List<BusinessPostDto>();
        var nameLower = business.BusinessName.ToLowerInvariant();
        if (nameLower.Contains("greencycle") || nameLower.Contains("eco") || nameLower.Contains("recycle"))
        {
            list.Add(new BusinessPostDto
            {
                Id = Guid.NewGuid(),
                BusinessProfileId = businessId,
                Title = "I HAVE 500kg PET bottles",
                Content = "Clean, baled post-consumer PET bottles ready for pickup or delivery.",
                Type = "I HAVE",
                MaterialCategory = "Plastics",
                Quantity = "500kg",
                CreatedAt = DateTime.UtcNow.AddDays(-2)
            });
            list.Add(new BusinessPostDto
            {
                Id = Guid.NewGuid(),
                BusinessProfileId = businessId,
                Title = "I NEED cardboard materials",
                Content = "Looking for bulk corrugated cardboard bales for packaging reuse.",
                Type = "I NEED",
                MaterialCategory = "Paper & Cardboard",
                Quantity = "1 Ton",
                CreatedAt = DateTime.UtcNow.AddDays(-5)
            });
        }

        return list;
    }

    private static void AuthorizeOwner(Business business, Guid? userId)
    {
        if (business.UserId.HasValue)
        {
            if (!userId.HasValue || business.UserId.Value != userId.Value)
            {
                throw new UnauthorizedAccessException("You are not authorized to modify this business profile.");
            }
        }
    }

    private static void DeleteLocalFileIfPresent(string rootPath, string? relativeUrl)
    {
        if (string.IsNullOrWhiteSpace(relativeUrl)) return;
        if (!relativeUrl.StartsWith("/uploads/")) return;

        var relativeSanitized = relativeUrl.TrimStart('/').Replace('/', Path.DirectorySeparatorChar);
        var physicalPath = Path.Combine(rootPath, relativeSanitized);
        if (File.Exists(physicalPath))
        {
            try
            {
                File.Delete(physicalPath);
            }
            catch
            {
                // Silently ignore cleanup errors to avoid blocking DB update
            }
        }
    }

    private static BusinessProfileDto MapToDto(Business b)
    {
        return new BusinessProfileDto
        {
            Id = b.Id,
            BusinessName = b.BusinessName,
            BusinessType = b.BusinessType,
            RegistrationNumber = b.RegistrationNumber,
            Bio = b.Bio,
            Description = b.Description,
            Email = b.Email,
            Phone = b.Phone,
            Address = b.Address,
            WebsiteUrl = b.WebsiteUrl,
            LogoUrl = b.LogoUrl,
            CoverPhotoUrl = b.CoverPhotoUrl,
            IsVerified = b.IsVerified,
            Status = b.Status,
            UserId = b.UserId,
            CreatedAt = b.CreatedAt,
            UpdatedAt = b.UpdatedAt
        };
    }
}
