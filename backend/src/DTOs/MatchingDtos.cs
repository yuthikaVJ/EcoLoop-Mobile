using System.ComponentModel.DataAnnotations;

namespace EcoLoop.Api.DTOs;

// ---- Internal API used by the Python AI service's tools ------------------------------

// The minimum a matching agent needs: no owner name, email or phone (spec section 18).
public record AiPostDto(
    Guid Id,
    string Type,
    string Title,
    string Category,
    string Description,
    string Quantity,
    string Unit,
    string Location,
    string DeliveryMethod,
    bool SellerDeliveryAvailable,
    string? Availability,
    string? Condition,
    DateTime CreatedAt);

public class AiCandidateSearchRequest
{
    [Required, MinLength(1), MaxLength(3)]
    public List<string> Categories { get; set; } = [];

    [Range(1, 20)]
    public int Limit { get; set; } = 15;
}

public class AiDistanceRequest
{
    public Guid CandidateId { get; set; }
}

public class AiStateReport
{
    [Required]
    public string State { get; set; } = string.Empty;

    [MaxLength(300)]
    public string? Note { get; set; }
}

// Result the Python service returns for POST /workflows/run.
public class AiWorkflowResult
{
    public string WorkflowId { get; set; } = string.Empty;
    public string Outcome { get; set; } = string.Empty;
    public string? Reason { get; set; }
    public List<AiMatchResult> Matches { get; set; } = [];
    public System.Text.Json.JsonElement? Trace { get; set; }
}

public class AiMatchResult
{
    public Guid CandidateId { get; set; }
    public decimal MatchScore { get; set; }
    public List<string> Reasons { get; set; } = [];
    public List<string> Warnings { get; set; } = [];
    public decimal? QuantityCoverage { get; set; }
    public double? DistanceKm { get; set; }
    public string RequiredAction { get; set; } = string.Empty;
}

// ---- What the mobile app sees --------------------------------------------------------

public record MatchListingDto(
    Guid Id,
    string Type,
    string Title,
    string Category,
    string Quantity,
    string Unit,
    string Location,
    string? ImageUrl,
    string? Seller,
    bool SellerIsVerified,
    Guid OwnerBusinessId);

public record MatchSuggestionDto(
    Guid Id,
    decimal Score,
    List<string> Reasons,
    List<string> Warnings,
    decimal? QuantityCoverage,
    double? DistanceKm,
    string MyDecision,
    string OtherDecision,
    MatchListingDto MyListing,
    MatchListingDto OtherListing,
    DateTime CreatedAt);

public record MatchWorkflowStatusDto(
    Guid WorkflowId,
    string State,
    string? Outcome,
    string? Reason,
    int SuggestionCount,
    DateTime CreatedAt,
    DateTime? CompletedAt);

public record MatchConnectResultDto(Guid SuggestionId, Guid ChatListingId, Guid OtherBusinessId);

// The latest AI check for one of my active posts (null fields: never checked).
public record MatchActivityDto(
    Guid ListingId,
    string Title,
    string Type,
    string? State,
    string? Outcome,
    string? Reason,
    int SuggestionCount,
    DateTime? CheckedAt);

// ---- Admin web -----------------------------------------------------------------------

public record AdminMatchWorkflowDto(
    Guid Id,
    Guid ListingId,
    string ListingTitle,
    string ListingType,
    string OwnerName,
    string State,
    string? Outcome,
    string? Reason,
    int SuggestionCount,
    DateTime CreatedAt,
    DateTime? CompletedAt);

public record AdminMatchWorkflowDetailsDto(
    AdminMatchWorkflowDto Workflow,
    System.Text.Json.JsonElement StateHistory,
    System.Text.Json.JsonElement? Trace);
