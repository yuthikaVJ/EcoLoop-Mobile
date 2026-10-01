using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using EcoLoop.Api.Data;
using EcoLoop.Api.Models;
using Google.Apis.Auth;
using System.Security.Cryptography;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;

namespace EcoLoop.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private readonly EcoLoopDbContext _db;
    private readonly IConfiguration _config;

    public AuthController(EcoLoopDbContext db, IConfiguration config)
    {
        _db = db;
        _config = config;
    }

    [HttpPost("google-login")]
    public async Task<IActionResult> GoogleLogin([FromBody] GoogleLoginRequest request)
    {
        try
        {
            var settings = new GoogleJsonWebSignature.ValidationSettings()
            {
                Audience = new List<string>() { _config["Authentication:Google:ClientId"]! }
            };

            // This validates the token cryptographically with Google's public keys
            var payload = await GoogleJsonWebSignature.ValidateAsync(request.IdToken, settings);

            // Check if business exists with this GoogleId or Email
            var business = await _db.Businesses
                .FirstOrDefaultAsync(b => b.GoogleId == payload.Subject || b.Email == payload.Email);

            if (business == null)
            {
                // Register new business
                business = new Business
                {
                    GoogleId = payload.Subject,
                    Email = payload.Email,
                    BusinessName = payload.Name,
                    LogoUrl = payload.Picture,
                    IsVerified = false
                };
                _db.Businesses.Add(business);
                await _db.SaveChangesAsync();
            }
            else if (business.GoogleId == null)
            {
                // Link Google account to existing email-based business
                business.GoogleId = payload.Subject;
                business.LogoUrl ??= payload.Picture;
                await _db.SaveChangesAsync();
            }

            // Generate JWT Token
            var (accessToken, jwtId) = GenerateJwtToken(business);
            
            // Generate Refresh Token
            var refreshToken = new RefreshToken
            {
                Token = Convert.ToBase64String(RandomNumberGenerator.GetBytes(64)),
                JwtId = jwtId,
                BusinessId = business.Id,
                CreationDate = DateTime.UtcNow,
                ExpiryDate = DateTime.UtcNow.AddDays(30)
            };
            
            _db.RefreshTokens.Add(refreshToken);
            await _db.SaveChangesAsync();

            return Ok(new { 
                Token = accessToken, 
                RefreshToken = refreshToken.Token,
                BusinessId = business.Id, 
                BusinessName = business.BusinessName, 
                LogoUrl = business.LogoUrl 
            });
        }
        catch (InvalidJwtException)
        {
            return Unauthorized(new { message = "Invalid Google ID token." });
        }
    }

    private (string token, string jwtId) GenerateJwtToken(Business business)
    {
        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_config["Jwt:Key"]!));
        var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);
        
        var jwtId = Guid.NewGuid().ToString();

        var claims = new[]
        {
            new Claim(ClaimTypes.NameIdentifier, business.Id.ToString()),
            new Claim(ClaimTypes.Email, business.Email ?? ""),
            new Claim(ClaimTypes.Name, business.BusinessName),
            new Claim(JwtRegisteredClaimNames.Jti, jwtId)
        };

        var token = new JwtSecurityToken(
            issuer: _config["Jwt:Issuer"],
            audience: _config["Jwt:Audience"],
            claims: claims,
            expires: DateTime.UtcNow.AddMinutes(15), // Short lived access token
            signingCredentials: creds
        );

        return (new JwtSecurityTokenHandler().WriteToken(token), jwtId);
    }
    
    [HttpPost("refresh")]
    public async Task<IActionResult> RefreshToken([FromBody] RefreshTokenRequest request)
    {
        // 1. Validate the structure of the access token
        var tokenHandler = new JwtSecurityTokenHandler();
        var principal = GetPrincipalFromExpiredToken(request.AccessToken);
        if (principal == null)
            return Unauthorized("Invalid token");

        var jti = principal.Claims.FirstOrDefault(c => c.Type == JwtRegisteredClaimNames.Jti)?.Value;
        if (jti == null)
            return Unauthorized("Invalid token");
            
        var businessIdStr = principal.Claims.FirstOrDefault(c => c.Type == ClaimTypes.NameIdentifier)?.Value;
        if (!Guid.TryParse(businessIdStr, out var businessId))
            return Unauthorized("Invalid token");

        // 2. Validate the refresh token against the database
        var storedRefreshToken = await _db.RefreshTokens.FirstOrDefaultAsync(x => x.Token == request.RefreshToken);
        if (storedRefreshToken == null)
            return Unauthorized("Refresh token does not exist");
            
        if (DateTime.UtcNow > storedRefreshToken.ExpiryDate)
            return Unauthorized("Refresh token has expired");
            
        if (storedRefreshToken.Invalidated)
            return Unauthorized("Refresh token has been invalidated");
            
        if (storedRefreshToken.Used)
            return Unauthorized("Refresh token has been used");
            
        if (storedRefreshToken.JwtId != jti)
            return Unauthorized("Refresh token does not match this JWT");

        // 3. Mark the token as used
        storedRefreshToken.Used = true;
        _db.RefreshTokens.Update(storedRefreshToken);
        await _db.SaveChangesAsync();

        // 4. Generate new tokens
        var business = await _db.Businesses.FindAsync(businessId);
        if (business == null)
            return Unauthorized("User no longer exists");

        var (newAccessToken, newJwtId) = GenerateJwtToken(business);
        
        var newRefreshToken = new RefreshToken
        {
            Token = Convert.ToBase64String(RandomNumberGenerator.GetBytes(64)),
            JwtId = newJwtId,
            BusinessId = business.Id,
            CreationDate = DateTime.UtcNow,
            ExpiryDate = DateTime.UtcNow.AddDays(30)
        };
        
        _db.RefreshTokens.Add(newRefreshToken);
        await _db.SaveChangesAsync();

        return Ok(new {
            Token = newAccessToken,
            RefreshToken = newRefreshToken.Token
        });
    }

    private ClaimsPrincipal? GetPrincipalFromExpiredToken(string token)
    {
        var tokenValidationParameters = new TokenValidationParameters
        {
            ValidateAudience = true,
            ValidAudience = _config["Jwt:Audience"],
            ValidateIssuer = true,
            ValidIssuer = _config["Jwt:Issuer"],
            ValidateIssuerSigningKey = true,
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_config["Jwt:Key"]!)),
            ValidateLifetime = false // Here we are saying that we don't care about the token's expiration date
        };

        var tokenHandler = new JwtSecurityTokenHandler();
        var principal = tokenHandler.ValidateToken(token, tokenValidationParameters, out var securityToken);
        var jwtSecurityToken = securityToken as JwtSecurityToken;
        if (jwtSecurityToken == null || !jwtSecurityToken.Header.Alg.Equals(SecurityAlgorithms.HmacSha256, StringComparison.InvariantCultureIgnoreCase))
            throw new SecurityTokenException("Invalid token");

        return principal;
    }
}

public class GoogleLoginRequest
{
    public string IdToken { get; set; } = string.Empty;
}

public class RefreshTokenRequest
{
    public string AccessToken { get; set; } = string.Empty;
    public string RefreshToken { get; set; } = string.Empty;
}
