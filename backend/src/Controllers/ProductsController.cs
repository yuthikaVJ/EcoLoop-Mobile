using EcoLoop.Api.DTOs;
using EcoLoop.Api.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace EcoLoop.Api.Controllers;

[ApiController]
[Route("api/products")]
public class ProductsController : ControllerBase
{
    private readonly IProductService _service;

    public ProductsController(IProductService service)
    {
        _service = service;
    }

    [HttpGet]
    public async Task<IActionResult> GetProducts(
        [FromQuery] string? search,
        [FromQuery] Guid? categoryId,
        [FromQuery] string? materialType,
        [FromQuery] decimal? minPrice,
        [FromQuery] decimal? maxPrice,
        [FromQuery] string sort = "newest",
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20)
    {
        var result = await _service.GetProductsAsync(
            search,
            categoryId,
            materialType,
            minPrice,
            maxPrice,
            sort,
            page,
            pageSize);

        return Ok(result);
    }

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> GetProduct(Guid id)
    {
        var product = await _service.GetByIdAsync(id);

        return product == null
            ? NotFound(new { message = "Product not found." })
            : Ok(product);
    }

    [HttpPost]
    public async Task<IActionResult> CreateProduct(
        [FromBody] CreateProductRequest request)
    {
        if (request.Price < 0)
            return BadRequest("Price cannot be negative.");

        var product = await _service.CreateAsync(request);

        return CreatedAtAction(
            nameof(GetProduct),
            new { id = product.Id },
            product);
    }

    [HttpPut("{id:guid}")]
    public async Task<IActionResult> UpdateProduct(
        Guid id,
        [FromBody] UpdateProductRequest request)
    {
        var product = await _service.UpdateAsync(id, request);

        return product == null
            ? NotFound(new { message = "Product not found." })
            : Ok(product);
    }

    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> DisableProduct(Guid id)
    {
        var disabled = await _service.DisableAsync(id);

        return disabled
            ? NoContent()
            : NotFound(new { message = "Product not found." });
    }
}