using System.Text.Json;
using EcoLoop.Api.Data;
using EcoLoop.Api.DTOs;
using EcoLoop.Api.Hubs;
using EcoLoop.Api.Models;
using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;

namespace EcoLoop.Api.Services.Matching;

// Server side of the agentic matching workflow. The Python service recommends;
// everything here re-validates, persists and enforces authorization (spec sections
// 9, 10, 13 and 18). Nothing the AI returns can connect users by itself.
public class MatchingService(
    EcoLoopDbContext db,
    IMatchingQueue queue,
    DeliveryRouteService routes,
    ILogger<MatchingService> logger,
    NotificationService? notifications = null,
    IHubContext<ChatHub>? chatHub = null)
{
    private const int MaxSuggestionsPerRun = 5;
    private const int MaxTraceChars = 200_000;
    private static readonly TimeSpan RerunCooldown = TimeSpan.FromMinutes(10);

    // ---- Starting a workflow ---------------------------------------------------------

    /// Queues matching for an active post owned by <paramref name="ownerId"/>. A run
    /// already in progress for the same post is reused instead of starting another.
    public async Task<MatchWorkflow> StartAsync(Guid listingId, Guid ownerId)
    {
        var listing = await db.MaterialListings.AsNoTracking().FirstOrDefaultAsync(l => l.Id == listingId)
            ?? throw new KeyNotFoundException("Listing not found.");
        if (listing.BusinessId != ownerId)
            throw new UnauthorizedAccessException("You can only run matching for your own posts.");
        if (listing.Status != ListingStatus.Active)
            throw new InvalidOperationException("Only active posts can be matched.");

        var final = MatchWorkflowState.Final.ToList();
        var since = DateTime.UtcNow - RerunCooldown;
        var running = await db.MatchWorkflows
            .Where(w => w.ListingId == listingId && !final.Contains(w.State) && w.CreatedAt > since)
            .OrderByDescending(w => w.CreatedAt)
            .FirstOrDefaultAsync();
        if (running != null) return running;

        var workflow = new MatchWorkflow { ListingId = listingId, OwnerBusinessId = ownerId };
        AppendHistory(workflow, MatchWorkflowState.Matching, "Matching workflow created.");
        db.MatchWorkflows.Add(workflow);
        await db.SaveChangesAsync();
        queue.Enqueue(workflow.Id);
        return workflow;
    }

    // ---- Tools for the AI service (scoped to one running workflow) -------------------

    public async Task<AiPostDto> GetTriggerPostAsync(Guid workflowId)
    {
        var workflow = await RunningWorkflowAsync(workflowId);
        var listing = await db.MaterialListings.AsNoTracking().FirstAsync(l => l.Id == workflow.ListingId);
        return ToAiPost(listing);
    }

    public async Task<List<AiPostDto>> SearchCandidatesAsync(Guid workflowId, IEnumerable<string> categories, int limit)
    {
        var workflow = await RunningWorkflowAsync(workflowId);
        var wanted = categories.Select(c => c.Trim().ToLower()).Where(c => c.Length > 0).Distinct().ToList();
        var candidates = await EligibleCandidates(workflow)
            .Where(l => wanted.Contains(l.Category.ToLower()))
            .OrderByDescending(l => l.CreatedAt)
            .Take(Math.Clamp(limit, 1, 20))
            .ToListAsync();
        return candidates.Select(ToAiPost).ToList();
    }

    /// Road distance between the workflow's post and an eligible candidate, or null
    /// when the routing service can't tell.
    public async Task<double?> GetDistanceKmAsync(Guid workflowId, Guid candidateId, CancellationToken cancellationToken)
    {
        var workflow = await RunningWorkflowAsync(workflowId);
        var candidate = await EligibleCandidates(workflow).FirstOrDefaultAsync(l => l.Id == candidateId)
            ?? throw new UnauthorizedAccessException("That post is not a candidate for this workflow.");
        var trigger = await db.MaterialListings.AsNoTracking().FirstAsync(l => l.Id == workflow.ListingId);
        if (string.IsNullOrWhiteSpace(trigger.Location) || string.IsNullOrWhiteSpace(candidate.Location))
            return null;
        try
        {
            var route = await routes.CalculateAsync(new DeliveryRouteRequest(trigger.Location, candidate.Location), cancellationToken);
            return Math.Round(route.DistanceMeters / 1000.0, 1);
        }
        catch (Exception ex) when (ex is TransactionRuleException or HttpRequestException or TaskCanceledException)
        {
            return null;
        }
    }

    public async Task ReportStateAsync(Guid workflowId, string state, string? note)
    {
        if (!MatchWorkflowState.ReportableByAi.Contains(state))
            throw new ArgumentException("The AI service can only report progress states.");
        var workflow = await RunningWorkflowAsync(workflowId, tracked: true);
        workflow.State = state;
        AppendHistory(workflow, state, note);
        await db.SaveChangesAsync();
    }

    // ---- Applying the AI result (authoritative validation) ---------------------------

    public async Task ApplyResultAsync(Guid workflowId, AiWorkflowResult result)
    {
        var workflow = await db.MatchWorkflows.FirstAsync(w => w.Id == workflowId);
        var trigger = await db.MaterialListings.AsNoTracking().FirstAsync(l => l.Id == workflow.ListingId);
        workflow.TraceJson = TraceText(result.Trace);

        if (trigger.Status != ListingStatus.Active)
        {
            await FinishAsync(workflow, MatchWorkflowState.SafeFailure, MatchWorkflowOutcome.NoMatch, "The post is no longer active.");
            return;
        }

        var accepted = new List<(MatchSuggestion Suggestion, bool IsNew)>();
        if (result.Outcome == MatchWorkflowOutcome.Matches)
        {
            var eligible = await EligibleCandidates(workflow)
                .Where(l => result.Matches.Select(m => m.CandidateId).Contains(l.Id))
                .ToDictionaryAsync(l => l.Id);
            foreach (var match in result.Matches.DistinctBy(m => m.CandidateId).Take(MaxSuggestionsPerRun))
            {
                var problem = Reject(match, eligible);
                if (problem != null)
                {
                    logger.LogWarning("Workflow {WorkflowId}: rejected AI match {CandidateId}: {Problem}", workflowId, match.CandidateId, problem);
                    continue;
                }
                accepted.Add(await UpsertSuggestionAsync(workflow, trigger, eligible[match.CandidateId], match));
            }
        }

        if (accepted.Count > 0)
        {
            workflow.SuggestionCount = accepted.Count;
            workflow.State = MatchWorkflowState.MatchReady;
            AppendHistory(workflow, MatchWorkflowState.MatchReady, $"{accepted.Count} match(es) validated.");
            await FinishAsync(workflow, MatchWorkflowState.UserApproval, MatchWorkflowOutcome.Matches, null);
            await NotifyNewMatchesAsync(accepted.Where(a => a.IsNew).Select(a => a.Suggestion).ToList());
            return;
        }

        var outcome = result.Outcome is MatchWorkflowOutcome.NoMatch or MatchWorkflowOutcome.NeedsInfo or MatchWorkflowOutcome.Failed
            ? result.Outcome
            : MatchWorkflowOutcome.NoMatch;
        var reason = result.Outcome == MatchWorkflowOutcome.Matches
            ? "The suggested matches did not pass validation."
            : Truncate(result.Reason, 500) ?? "No reliable match found right now.";
        await FinishAsync(workflow, MatchWorkflowState.SafeFailure, outcome, reason);
    }

    public async Task FailAsync(Guid workflowId, string reason)
    {
        var workflow = await db.MatchWorkflows.FirstOrDefaultAsync(w => w.Id == workflowId);
        if (workflow == null || MatchWorkflowState.Final.Contains(workflow.State)) return;
        await FinishAsync(workflow, MatchWorkflowState.SafeFailure, MatchWorkflowOutcome.Failed, reason);
    }

    /// Workflows cut off by a server restart would otherwise look busy forever.
    public async Task RecoverInterruptedAsync()
    {
        var final = MatchWorkflowState.Final.ToList();
        var stuck = await db.MatchWorkflows.Where(w => !final.Contains(w.State)).ToListAsync();
        foreach (var workflow in stuck)
            await FinishAsync(workflow, MatchWorkflowState.SafeFailure, MatchWorkflowOutcome.Failed, "Interrupted by a server restart.");
    }

    private static string? Reject(AiMatchResult match, Dictionary<Guid, MaterialListing> eligible)
    {
        if (!eligible.ContainsKey(match.CandidateId)) return "not an eligible candidate";
        if (match.RequiredAction != "USER_APPROVAL") return "did not require user approval";
        if (match.MatchScore is < 0 or > 1) return "score out of range";
        if (match.Reasons.All(string.IsNullOrWhiteSpace)) return "no reasons given";
        if (match.QuantityCoverage is < 0 or > 1) return "quantity coverage out of range";
        return null;
    }

    private async Task<(MatchSuggestion, bool)> UpsertSuggestionAsync(
        MatchWorkflow workflow, MaterialListing trigger, MaterialListing candidate, AiMatchResult match)
    {
        var (have, need) = trigger.Type == ListingType.IHave ? (trigger, candidate) : (candidate, trigger);
        var suggestion = await db.MatchSuggestions.FirstOrDefaultAsync(s => s.HaveListingId == have.Id && s.NeedListingId == need.Id);
        var isNew = suggestion == null;
        if (suggestion == null)
        {
            suggestion = new MatchSuggestion { HaveListingId = have.Id, NeedListingId = need.Id };
            db.MatchSuggestions.Add(suggestion);
        }
        // Refresh the evidence; owners' decisions (incl. "Not interested") are kept.
        suggestion.WorkflowId = workflow.Id;
        suggestion.Score = Math.Round(match.MatchScore, 3);
        suggestion.Reasons = Clean(match.Reasons);
        suggestion.Warnings = Clean(match.Warnings);
        suggestion.QuantityCoverage = match.QuantityCoverage is null ? null : Math.Round(match.QuantityCoverage.Value, 3);
        suggestion.DistanceKm = match.DistanceKm;
        suggestion.UpdatedAt = DateTime.UtcNow;
        await db.SaveChangesAsync();
        return (suggestion, isNew);
    }

    private async Task NotifyNewMatchesAsync(List<MatchSuggestion> suggestions)
    {
        if (notifications == null || suggestions.Count == 0) return;
        var listingIds = suggestions.SelectMany(s => new[] { s.HaveListingId, s.NeedListingId }).Distinct().ToList();
        var listings = await db.MaterialListings.AsNoTracking().Where(l => listingIds.Contains(l.Id)).ToDictionaryAsync(l => l.Id);
        foreach (var suggestion in suggestions)
        {
            foreach (var listing in new[] { listings[suggestion.HaveListingId], listings[suggestion.NeedListingId] })
            {
                var tokens = await db.DeviceTokens.Where(d => d.BusinessId == listing.BusinessId).Select(d => d.Token).ToListAsync();
                await notifications.SendPushNotificationAsync(tokens,
                    "Potential match found",
                    $"EcoLoop found a potential match for your \"{Truncate(listing.Title, 60)}\" listing.",
                    new Dictionary<string, string> { ["type"] = "material_match", ["suggestionId"] = suggestion.Id.ToString() });
            }
        }
    }

    // ---- What users see and do -------------------------------------------------------

    public async Task<List<MatchSuggestionDto>> GetMineAsync(Guid me)
    {
        var suggestions = await SuggestionsWithListings()
            .Where(s => s.HaveListing!.Status == ListingStatus.Active && s.NeedListing!.Status == ListingStatus.Active)
            .Where(s => (s.HaveListing!.BusinessId == me && s.HaveOwnerDecision != MatchDecision.Dismissed) ||
                        (s.NeedListing!.BusinessId == me && s.NeedOwnerDecision != MatchDecision.Dismissed))
            .OrderByDescending(s => s.Score).ThenByDescending(s => s.UpdatedAt)
            .Take(50)
            .ToListAsync();
        return suggestions.Select(s => ToDto(s, me)).ToList();
    }

    public async Task<MatchConnectResultDto> ConnectAsync(Guid me, Guid suggestionId)
    {
        var suggestion = await ParticipantSuggestionAsync(me, suggestionId);
        var (mine, other, iAmHave) = Sides(suggestion, me);
        if (mine.Status != ListingStatus.Active || other.Status != ListingStatus.Active)
            throw new InvalidOperationException("One of the posts is no longer active.");

        var alreadyConnected = (iAmHave ? suggestion.HaveOwnerDecision : suggestion.NeedOwnerDecision) == MatchDecision.Connected;
        if (iAmHave) suggestion.HaveOwnerDecision = MatchDecision.Connected;
        else suggestion.NeedOwnerDecision = MatchDecision.Connected;
        suggestion.UpdatedAt = DateTime.UtcNow;

        var workflow = await db.MatchWorkflows.FirstAsync(w => w.Id == suggestion.WorkflowId);
        if (workflow.State != MatchWorkflowState.Connected)
        {
            workflow.State = MatchWorkflowState.Connected;
            AppendHistory(workflow, MatchWorkflowState.Connected, "A user approved the match and started a chat.");
        }

        if (!alreadyConnected)
        {
            // The user's approval - not the AI - creates the contact action (spec section 10).
            var message = new ChatMessage
            {
                ListingId = other.Id,
                SenderId = me,
                ReceiverId = other.BusinessId,
                Content = $"Hi! EcoLoop matched my {(iAmHave ? "I HAVE" : "I NEED")} post \"{Truncate(mine.Title, 80)}\" " +
                          $"with your post \"{Truncate(other.Title, 80)}\". Would you like to discuss it?",
            };
            db.ChatMessages.Add(message);
            await db.SaveChangesAsync();
            await DeliverChatAsync(message);
        }
        else
        {
            await db.SaveChangesAsync();
        }
        return new MatchConnectResultDto(suggestion.Id, other.Id, other.BusinessId);
    }

    public async Task DismissAsync(Guid me, Guid suggestionId)
    {
        var suggestion = await ParticipantSuggestionAsync(me, suggestionId);
        var (_, _, iAmHave) = Sides(suggestion, me);
        if (iAmHave) suggestion.HaveOwnerDecision = MatchDecision.Dismissed;
        else suggestion.NeedOwnerDecision = MatchDecision.Dismissed;
        suggestion.UpdatedAt = DateTime.UtcNow;
        await db.SaveChangesAsync();
    }

    /// Each of my active posts with its latest AI check, so users can see why
    /// they have no matches yet.
    public async Task<List<MatchActivityDto>> GetMyActivityAsync(Guid me)
    {
        var rows = await db.MaterialListings.AsNoTracking()
            .Where(l => l.BusinessId == me && l.Status == ListingStatus.Active)
            .OrderByDescending(l => l.CreatedAt)
            .Take(30)
            .Select(l => new
            {
                l.Id,
                l.Title,
                l.Type,
                Latest = db.MatchWorkflows
                    .Where(w => w.ListingId == l.Id)
                    .OrderByDescending(w => w.CreatedAt)
                    .Select(w => new { w.State, w.Outcome, w.Reason, w.CreatedAt })
                    .FirstOrDefault(),
                // Matches I can currently see for this post - including ones found
                // when the other user posted, not only by this post's own check.
                MatchCount = db.MatchSuggestions.Count(s =>
                    s.HaveListing!.Status == ListingStatus.Active && s.NeedListing!.Status == ListingStatus.Active &&
                    ((s.HaveListingId == l.Id && s.HaveOwnerDecision != MatchDecision.Dismissed) ||
                     (s.NeedListingId == l.Id && s.NeedOwnerDecision != MatchDecision.Dismissed))),
            })
            .ToListAsync();
        return rows.Select(r => new MatchActivityDto(
            r.Id, r.Title, r.Type == ListingType.IHave ? "I_HAVE" : "I_NEED",
            r.Latest?.State, r.Latest?.Outcome, r.Latest?.Reason, r.MatchCount, r.Latest?.CreatedAt)).ToList();
    }

    public async Task<MatchWorkflowStatusDto?> GetLatestStatusAsync(Guid me, Guid listingId)
    {
        var owns = await db.MaterialListings.AnyAsync(l => l.Id == listingId && l.BusinessId == me);
        if (!owns) throw new UnauthorizedAccessException("You can only view matching for your own posts.");
        return await db.MatchWorkflows.AsNoTracking()
            .Where(w => w.ListingId == listingId)
            .OrderByDescending(w => w.CreatedAt)
            .Select(w => new MatchWorkflowStatusDto(w.Id, w.State, w.Outcome, w.Reason, w.SuggestionCount, w.CreatedAt, w.CompletedAt))
            .FirstOrDefaultAsync();
    }

    // ---- Admin -----------------------------------------------------------------------

    public async Task<List<AdminMatchWorkflowDto>> GetWorkflowsAsync(string? state)
    {
        // Filter, order and limit the entities first: EF can't translate those
        // operations once rows are projected into DTO records.
        var workflows = db.MatchWorkflows.AsNoTracking();
        if (!string.IsNullOrWhiteSpace(state) && state != "all")
            workflows = workflows.Where(w => w.State == state);
        var page = await AdminWorkflows(workflows.OrderByDescending(w => w.CreatedAt).Take(200)).ToListAsync();
        return page.OrderByDescending(w => w.CreatedAt).ToList();
    }

    public async Task<AdminMatchWorkflowDetailsDto?> GetWorkflowAsync(Guid id)
    {
        var summary = await AdminWorkflows(db.MatchWorkflows.AsNoTracking().Where(w => w.Id == id)).FirstOrDefaultAsync();
        if (summary == null) return null;
        var raw = await db.MatchWorkflows.AsNoTracking().Where(w => w.Id == id)
            .Select(w => new { w.StateHistoryJson, w.TraceJson }).FirstAsync();
        using var history = JsonDocument.Parse(raw.StateHistoryJson);
        JsonElement? trace = null;
        if (raw.TraceJson != null)
        {
            using var traceDoc = JsonDocument.Parse(raw.TraceJson);
            trace = traceDoc.RootElement.Clone();
        }
        return new AdminMatchWorkflowDetailsDto(summary, history.RootElement.Clone(), trace);
    }

    private IQueryable<AdminMatchWorkflowDto> AdminWorkflows(IQueryable<MatchWorkflow> workflows) =>
        from w in workflows
        join l in db.MaterialListings on w.ListingId equals l.Id
        join b in db.Businesses on w.OwnerBusinessId equals b.Id
        select new AdminMatchWorkflowDto(w.Id, w.ListingId, l.Title, l.Type == ListingType.IHave ? "I_HAVE" : "I_NEED",
            b.BusinessName, w.State, w.Outcome, w.Reason, w.SuggestionCount, w.CreatedAt, w.CompletedAt);

    // ---- Helpers ---------------------------------------------------------------------

    /// Posts a workflow may consider: active, opposite type, not the requester's own
    /// (which also covers business profiles the requester posts as).
    private IQueryable<MaterialListing> EligibleCandidates(MatchWorkflow workflow)
    {
        var triggerType = db.MaterialListings.Where(l => l.Id == workflow.ListingId).Select(l => l.Type);
        return db.MaterialListings.AsNoTracking()
            .Where(l => l.Status == ListingStatus.Active
                        && l.BusinessId != workflow.OwnerBusinessId
                        && l.Id != workflow.ListingId
                        && !triggerType.Contains(l.Type));
    }

    private async Task<MatchWorkflow> RunningWorkflowAsync(Guid workflowId, bool tracked = false)
    {
        var query = tracked ? db.MatchWorkflows : db.MatchWorkflows.AsNoTracking();
        var workflow = await query.FirstOrDefaultAsync(w => w.Id == workflowId)
            ?? throw new KeyNotFoundException("Workflow not found.");
        if (MatchWorkflowState.Final.Contains(workflow.State))
            throw new InvalidOperationException("This workflow has already finished.");
        return workflow;
    }

    private IQueryable<MatchSuggestion> SuggestionsWithListings() => db.MatchSuggestions
        .Include(s => s.HaveListing!).ThenInclude(l => l.Business)
        .Include(s => s.HaveListing!).ThenInclude(l => l.PostedAsBusiness)
        .Include(s => s.NeedListing!).ThenInclude(l => l.Business)
        .Include(s => s.NeedListing!).ThenInclude(l => l.PostedAsBusiness);

    private async Task<MatchSuggestion> ParticipantSuggestionAsync(Guid me, Guid suggestionId)
    {
        var suggestion = await SuggestionsWithListings().FirstOrDefaultAsync(s => s.Id == suggestionId);
        // Non-participants get "not found" so suggestions can't be probed.
        if (suggestion == null || (suggestion.HaveListing!.BusinessId != me && suggestion.NeedListing!.BusinessId != me))
            throw new KeyNotFoundException("Match not found.");
        return suggestion;
    }

    private static (MaterialListing Mine, MaterialListing Other, bool IAmHave) Sides(MatchSuggestion s, Guid me) =>
        s.HaveListing!.BusinessId == me ? (s.HaveListing!, s.NeedListing!, true) : (s.NeedListing!, s.HaveListing!, false);

    private static MatchSuggestionDto ToDto(MatchSuggestion s, Guid me)
    {
        var (mine, other, iAmHave) = Sides(s, me);
        return new MatchSuggestionDto(s.Id, s.Score, s.Reasons, s.Warnings, s.QuantityCoverage, s.DistanceKm,
            iAmHave ? s.HaveOwnerDecision : s.NeedOwnerDecision,
            iAmHave ? s.NeedOwnerDecision : s.HaveOwnerDecision,
            ToMatchListing(mine), ToMatchListing(other), s.CreatedAt);
    }

    private static MatchListingDto ToMatchListing(MaterialListing l)
    {
        var seller = l.PostedAsBusiness ?? l.Business;
        return new MatchListingDto(l.Id, l.Type == ListingType.IHave ? "I_HAVE" : "I_NEED", l.Title, l.Category,
            l.Quantity, l.Unit, l.Location, l.ImageUrl, seller?.BusinessName, seller?.IsVerified ?? false, l.BusinessId);
    }

    private static AiPostDto ToAiPost(MaterialListing l) => new(
        l.Id, l.Type == ListingType.IHave ? "I_HAVE" : "I_NEED", l.Title, l.Category, l.Description,
        l.Quantity, l.Unit, l.Location, l.DeliveryMethod, l.SellerDeliveryAvailable, l.Availability, l.Condition, l.CreatedAt);

    private async Task DeliverChatAsync(ChatMessage message)
    {
        if (chatHub != null)
        {
            await chatHub.Clients.User(message.ReceiverId.ToString()).SendAsync("ReceiveMessage", new
            {
                id = message.Id, listingId = message.ListingId, senderId = message.SenderId,
                receiverId = message.ReceiverId, content = message.Content, createdAt = message.CreatedAt,
            });
        }
        if (notifications != null)
        {
            var tokens = await db.DeviceTokens.Where(d => d.BusinessId == message.ReceiverId).Select(d => d.Token).ToListAsync();
            await notifications.SendPushNotificationAsync(tokens, "New match connection", message.Content,
                new Dictionary<string, string>
                {
                    ["type"] = "chat_message",
                    ["listingId"] = message.ListingId.ToString(),
                    ["senderId"] = message.SenderId.ToString(),
                });
        }
    }

    private async Task FinishAsync(MatchWorkflow workflow, string state, string outcome, string? reason)
    {
        workflow.State = state;
        workflow.Outcome = outcome;
        workflow.Reason = reason;
        workflow.CompletedAt = DateTime.UtcNow;
        AppendHistory(workflow, state, reason);
        await db.SaveChangesAsync();
    }

    private static void AppendHistory(MatchWorkflow workflow, string state, string? note)
    {
        var history = JsonSerializer.Deserialize<List<Dictionary<string, object?>>>(workflow.StateHistoryJson) ?? [];
        history.Add(new Dictionary<string, object?> { ["state"] = state, ["at"] = DateTime.UtcNow, ["note"] = Truncate(note, 300) });
        workflow.StateHistoryJson = JsonSerializer.Serialize(history);
    }

    private static string? TraceText(JsonElement? trace)
    {
        if (trace is null || trace.Value.ValueKind == JsonValueKind.Undefined) return null;
        var text = trace.Value.GetRawText();
        return text.Length <= MaxTraceChars ? text : JsonSerializer.Serialize(new { truncated = true, size = text.Length });
    }

    private static List<string> Clean(IEnumerable<string> lines) => lines
        .Select(l => Truncate(string.Join(' ', (l ?? "").Split((char[]?)null, StringSplitOptions.RemoveEmptyEntries)), 160)!)
        .Where(l => l.Length > 0).Distinct().Take(5).ToList();

    private static string? Truncate(string? text, int max) =>
        text == null ? null : text.Length <= max ? text : text[..max];
}
