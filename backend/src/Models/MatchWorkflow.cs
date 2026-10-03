namespace EcoLoop.Api.Models;

// States from the AI matching spec (section 11).
public static class MatchWorkflowState
{
    public const string Matching = "MATCHING";
    public const string Analyzing = "ANALYZING";
    public const string CandidatesFound = "CANDIDATES_FOUND";
    public const string Validating = "VALIDATING";
    public const string MatchReady = "MATCH_READY";
    public const string UserApproval = "USER_APPROVAL";
    public const string Connected = "CONNECTED";
    public const string SafeFailure = "SAFE_FAILURE";

    // States the Python service may report while it works.
    public static readonly string[] ReportableByAi = [Analyzing, CandidatesFound, Validating];
    public static readonly string[] Final = [UserApproval, Connected, SafeFailure];
}

// Why a workflow ended: MATCHES, NO_MATCH, NEEDS_INFO or FAILED.
public static class MatchWorkflowOutcome
{
    public const string Matches = "MATCHES";
    public const string NoMatch = "NO_MATCH";
    public const string NeedsInfo = "NEEDS_INFO";
    public const string Failed = "FAILED";
}

// One run of the agentic matching workflow for one post, kept for auditability.
public class MatchWorkflow
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid ListingId { get; set; }
    public MaterialListing? Listing { get; set; }
    // Account that owns the post; tools only ever see data this account may see.
    public Guid OwnerBusinessId { get; set; }
    public string State { get; set; } = MatchWorkflowState.Matching;
    public string? Outcome { get; set; }
    public string? Reason { get; set; }
    // [{state, at, note}] in order (jsonb).
    public string StateHistoryJson { get; set; } = "[]";
    // Agent outputs, model calls and validator decisions returned by the AI service (jsonb).
    public string? TraceJson { get; set; }
    public int SuggestionCount { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? CompletedAt { get; set; }
}
