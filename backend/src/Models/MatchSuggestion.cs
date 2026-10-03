namespace EcoLoop.Api.Models;

// Each owner decides independently: PENDING -> CONNECTED or DISMISSED.
public static class MatchDecision
{
    public const string Pending = "PENDING";
    public const string Connected = "CONNECTED";
    public const string Dismissed = "DISMISSED";
}

// A potential I HAVE <-> I NEED pair recommended by the AI. One row per pair;
// later workflows refresh it but never resurrect a dismissed suggestion.
public class MatchSuggestion
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid WorkflowId { get; set; }
    public MatchWorkflow? Workflow { get; set; }
    public Guid HaveListingId { get; set; }
    public MaterialListing? HaveListing { get; set; }
    public Guid NeedListingId { get; set; }
    public MaterialListing? NeedListing { get; set; }
    public decimal Score { get; set; }
    public List<string> Reasons { get; set; } = [];
    public List<string> Warnings { get; set; } = [];
    public decimal? QuantityCoverage { get; set; }
    public double? DistanceKm { get; set; }
    public string HaveOwnerDecision { get; set; } = MatchDecision.Pending;
    public string NeedOwnerDecision { get; set; } = MatchDecision.Pending;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
}
