using EcoLoop.Api.DTOs;
using EcoLoop.Api.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace EcoLoop.Api.Controllers;

[ApiController]
[Route("api/products/{productId:guid}/images")]
public class ProductImagesController : ControllerBase
{
    private readonly IProductImageService _service;

    public ProductImagesController(IProductImageService service)
    {
        _service = service;
    }

    [HttpGet]
    public async Task<IActionResult> GetImages(Guid productId)
    {
        return Ok(await _service.GetByProductIdAsync(productId));
    }

    [HttpPost]
    public async Task<IActionResult> CreateImage(
        Guid productId,
        CreateProductImageRequest request)
    {
        var image = await _service.CreateAsync(productId, request);

        return image == null
            ? NotFound(new { message = "Product not found." })
            : Ok(image);
    }

    [HttpPut("{imageId:guid}")]
    public async Task<IActionResult> UpdateImage(
        Guid productId,
        Guid imageId,
        UpdateProductImageRequest request)
    {
        var image = await _service.UpdateAsync(
            productId,
            imageId,
            request);

        return image == null
            ? NotFound()
            : Ok(image);
    }

    [HttpDelete("{imageId:guid}")]
    public async Task<IActionResult> DeleteImage(
        Guid productId,
        Guid imageId)
    {
        return await _service.DeleteAsync(productId, imageId)
            ? NoContent()
            : NotFound();
    }
}