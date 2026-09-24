using EcoLoop.Api.DTOs;

namespace EcoLoop.Api.Services;

public static class TransactionRules
{
    public const decimal MaxAmount = 9999999999.99m;

    public static string? ValidateTerms(decimal quantity, string? unit, decimal price)
    {
        if (quantity <= 0 || quantity > 999999999.999m || decimal.Round(quantity, 3) != quantity)
            return "Quantity must be positive, at most 999999999.999, with at most three decimal places.";
        if (string.IsNullOrWhiteSpace(unit) || unit.Trim().Length > 50) return "Unit must contain 1 to 50 characters.";
        if (price < 0 || price > MaxAmount || decimal.Round(price, 2) != price)
            return "Unit price must be nonnegative, with at most two decimal places.";
        if (quantity * price > MaxAmount) return "Total amount exceeds the supported limit.";
        return null;
    }

    public static string? ValidateDelivery(DeliveryInputDto? delivery)
    {
        if (delivery == null || delivery.Method is < 0 or > 1) return "Invalid delivery method.";
        if (delivery.Location?.Length > 500) return "Location must not exceed 500 characters.";
        if (delivery.Method == 1 && string.IsNullOrWhiteSpace(delivery.Location))
            return "A delivery location is required for seller delivery.";
        return null;
    }
}

public sealed class TransactionRuleException(int statusCode, string message) : Exception(message)
{
    public int StatusCode { get; } = statusCode;
}
