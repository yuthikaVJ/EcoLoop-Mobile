using EcoLoop.Api.Data;
using EcoLoop.Api.Services;
using EcoLoop.Api.Services.Interfaces;
using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using System.Text;
using FirebaseAdmin;
using Google.Apis.Auth.OAuth2;

DotNetEnv.Env.Load();
var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers();
builder.Services.AddSignalR();
builder.Services.AddSingleton<NotificationService>();

// Initialize Firebase Admin SDK
var firebaseKeyPath = Path.Combine(builder.Environment.ContentRootPath, "firebase-key.json");
if (File.Exists(firebaseKeyPath))
{
    FirebaseApp.Create(new AppOptions()
    {
        Credential = GoogleCredential.FromFile(firebaseKeyPath)
    });
}

builder.Services.AddDbContext<EcoLoopDbContext>(options =>
    options.UseNpgsql(
        builder.Configuration.GetConnectionString("DefaultConnection")));

builder.Services.AddScoped<IProductService, ProductService>();
builder.Services.AddScoped<ICategoryService, CategoryService>();
builder.Services.AddScoped<IProductImageService, ProductImageService>();
builder.Services.AddScoped<IInventoryService, InventoryService>();
builder.Services.AddScoped<IMaterialListingService, MaterialListingService>();
builder.Services.AddScoped<IBusinessService, BusinessService>();

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// Configure JWT Authentication
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer = builder.Configuration["Jwt:Issuer"],
            ValidAudience = builder.Configuration["Jwt:Audience"],
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(builder.Configuration["Jwt:Key"]!))
        };
    });

builder.Services.AddCors(options =>
{
    options.AddPolicy("MobileApp", policy =>
    {
        policy.AllowAnyOrigin()
            .AllowAnyHeader()
            .AllowAnyMethod();
    });
});

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseStaticFiles();
app.UseCors("MobileApp");
app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();
app.MapHub<EcoLoop.Api.Hubs.ChatHub>("/chatHub");

// Seed a dummy business so the frontend can create listings with Guid.Empty
using (var scope = app.Services.CreateScope())
{
    var context = scope.ServiceProvider.GetRequiredService<EcoLoopDbContext>();
    var dummyBusinessId = Guid.Parse("11111111-1111-1111-1111-111111111111");
    if (!context.Businesses.Any(b => b.Id == dummyBusinessId))
    {
        context.Businesses.Add(new EcoLoop.Api.Models.Business 
        { 
            Id = dummyBusinessId, 
            BusinessName = "EcoLoop Default Business", 
            IsVerified = true 
        });
        context.SaveChanges();
    }

    // Seed default product categories
    var defaultCategories = new[]
    {
        "Electronics", "Clothing & Apparel", "Home & Garden",
        "Food & Beverages", "Health & Beauty", "Sports & Outdoors",
        "Furniture", "Stationery", "Toys & Games", "Other"
    };

    foreach (var catName in defaultCategories)
    {
        if (!context.ProductCategories.Any(c => c.Name == catName))
        {
            context.ProductCategories.Add(new EcoLoop.Api.Models.ProductCategory
            {
                Name = catName,
                Description = $"Sustainable {catName} products"
            });
        }
    }
    context.SaveChanges();
}

app.MapGet("/api/seed-business", (EcoLoopDbContext db) => {
    try {
        var id = Guid.Parse("11111111-1111-1111-1111-111111111111");
        if (!db.Businesses.Any(b => b.Id == id))
        {
            db.Businesses.Add(new EcoLoop.Api.Models.Business { Id = id, BusinessName = "Seeded", IsVerified = true });
            db.SaveChanges();
            return "Seeded";
        }
        return "Already exists";
    } catch (Exception ex) {
        return ex.ToString();
    }
});

app.Run();