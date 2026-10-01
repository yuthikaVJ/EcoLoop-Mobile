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

builder.Services.AddControllers(options => options.Filters.Add<EcoLoop.Api.Controllers.TransactionExceptionFilter>());
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
builder.Services.AddScoped<IMaterialTransactionService, MaterialTransactionService>();
builder.Services.AddScoped<IProductOrderService, ProductOrderService>();
builder.Services.AddScoped<DeliveryLocationService>();
builder.Services.AddScoped<DeliveryTrackingService>();
builder.Services.AddHttpClient<DeliveryRouteService>(client =>
{
    client.Timeout = TimeSpan.FromSeconds(15);
    // Nominatim's usage policy rejects requests without an identifying User-Agent.
    client.DefaultRequestHeaders.UserAgent.ParseAdd("EcoLoop/1.0 (student project)");
});

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
        // WebSockets can't send an Authorization header, so SignalR clients pass the
        // token as ?access_token=...; accept it for the chat hub only.
        options.Events = new JwtBearerEvents
        {
            OnMessageReceived = context =>
            {
                var accessToken = context.Request.Query["access_token"];
                if (!string.IsNullOrEmpty(accessToken) && context.HttpContext.Request.Path.StartsWithSegments("/chatHub"))
                    context.Token = accessToken;
                return Task.CompletedTask;
            }
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
    // Apply any pending migrations so the database schema always matches the models.
    context.Database.Migrate();
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

    // Temporary mobile demo identity until the team's authentication component is integrated.
    var demoBuyerId = Guid.Parse("22222222-2222-2222-2222-222222222222");
    if (!context.Businesses.Any(b => b.Id == demoBuyerId))
    {
        context.Businesses.Add(new EcoLoop.Api.Models.Business
        {
            Id = demoBuyerId,
            BusinessName = "EcoLoop Demo Buyer",
            IsVerified = true
        });
        context.SaveChanges();
    }
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
