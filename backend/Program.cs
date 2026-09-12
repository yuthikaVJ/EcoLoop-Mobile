using EcoLoop.Api.Data;
using EcoLoop.Api.Services;
using EcoLoop.Api.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers();

builder.Services.AddDbContext<EcoLoopDbContext>(options =>
    options.UseNpgsql(
        builder.Configuration.GetConnectionString("DefaultConnection")));

builder.Services.AddScoped<IProductService, ProductService>();
builder.Services.AddScoped<ICategoryService, CategoryService>();
builder.Services.AddScoped<IProductImageService, ProductImageService>();
builder.Services.AddScoped<IInventoryService, InventoryService>();
builder.Services.AddScoped<IMaterialListingService, MaterialListingService>();

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

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
app.MapControllers();

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