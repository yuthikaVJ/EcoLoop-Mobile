using EcoLoop.Api.DTOs;
using EcoLoop.Api.Models;
using EcoLoop.Api.Services;
using EcoLoop.Api.Services.Matching;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging.Abstractions;

namespace EcoLoop.Backend.Tests;

public class MatchingServiceTests
{
    private sealed class RecordingQueue : IMatchingQueue
    {
        public List<Guid> Queued { get; } = [];
        public void Enqueue(Guid workflowId) => Queued.Add(workflowId);
        public IAsyncEnumerable<Guid> ReadAllAsync(CancellationToken cancellationToken) => throw new NotSupportedException();
    }

    // Routing is never reachable in tests, so distances come back as "unknown".
    private sealed class NoNetwork : HttpMessageHandler
    {
        protected override Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken cancellationToken) =>
            throw new HttpRequestException("offline");
    }

    private static (MatchingService Service, RecordingQueue Queue) Create(Component4TestContext context)
    {
        var queue = new RecordingQueue();
        var routes = new DeliveryRouteService(new HttpClient(new NoNetwork()), new ConfigurationBuilder().Build());
        return (new MatchingService(context.Db, queue, routes, NullLogger<MatchingService>.Instance), queue);
    }

    private static AiMatchResult Match(Guid candidateId, string action = "USER_APPROVAL") => new()
    {
        CandidateId = candidateId, MatchScore = 0.9m, Reasons = ["Material type matches"],
        Warnings = [], QuantityCoverage = 1m, RequiredAction = action,
    };

    private static async Task<MatchWorkflow> StartedWorkflowAsync(Component4TestContext context, MatchingService service, MaterialListing need)
    {
        var workflow = await service.StartAsync(need.Id, need.BusinessId);
        return await context.Db.MatchWorkflows.AsNoTracking().FirstAsync(w => w.Id == workflow.Id);
    }

    [Fact]
    public async Task Start_OnlyForOwnersActivePost_AndQueuesOnce()
    {
        await using var context = await Component4TestContext.CreateAsync();
        var (service, queue) = Create(context);
        var need = await context.AddListingAsync(type: ListingType.INeed); // owned by Buyer

        await Assert.ThrowsAsync<UnauthorizedAccessException>(() => service.StartAsync(need.Id, context.Seller.Id));
        var first = await service.StartAsync(need.Id, context.Buyer.Id);
        var again = await service.StartAsync(need.Id, context.Buyer.Id);

        Assert.Equal(first.Id, again.Id); // a running workflow is reused
        Assert.Single(queue.Queued);
        Assert.Equal(MatchWorkflowState.Matching, first.State);
    }

    [Fact]
    public async Task Tools_OnlySeeOppositeActivePostsOfOtherAccounts()
    {
        await using var context = await Component4TestContext.CreateAsync();
        var (service, _) = Create(context);
        var need = await context.AddListingAsync(type: ListingType.INeed);   // Buyer's I NEED
        var have = await context.AddListingAsync();                          // Seller's I HAVE
        var ownHave = await context.AddListingAsync();                       // Buyer's own I HAVE
        ownHave.BusinessId = context.Buyer.Id;
        var sold = await context.AddListingAsync();
        sold.Status = ListingStatus.Completed;
        await context.Db.SaveChangesAsync();
        var workflow = await StartedWorkflowAsync(context, service, need);

        var found = await service.SearchCandidatesAsync(workflow.Id, ["plastics"], 15);

        Assert.Equal([have.Id], found.Select(f => f.Id));
        Assert.Equal("I_HAVE", found[0].Type);
        await Assert.ThrowsAsync<UnauthorizedAccessException>(() => service.GetDistanceKmAsync(workflow.Id, ownHave.Id, default));
        Assert.Null(await service.GetDistanceKmAsync(workflow.Id, have.Id, default)); // routing offline -> unknown
    }

    [Fact]
    public async Task ApplyResult_RevalidatesEveryAiMatch()
    {
        await using var context = await Component4TestContext.CreateAsync();
        var (service, _) = Create(context);
        var need = await context.AddListingAsync(type: ListingType.INeed);
        var have = await context.AddListingAsync();
        var other = await context.AddListingAsync();
        var workflow = await StartedWorkflowAsync(context, service, need);

        await service.ApplyResultAsync(workflow.Id, new AiWorkflowResult
        {
            Outcome = MatchWorkflowOutcome.Matches,
            Matches =
            [
                Match(have.Id),
                Match(other.Id, action: "AUTO_CONNECT"),  // tried to skip approval
                Match(Guid.NewGuid()),                    // a post the tools never returned
                Match(need.Id),                           // same side / own post
            ],
        });

        var saved = await context.Db.MatchSuggestions.SingleAsync();
        Assert.Equal((have.Id, need.Id), (saved.HaveListingId, saved.NeedListingId));
        var finished = await context.Db.MatchWorkflows.AsNoTracking().FirstAsync(w => w.Id == workflow.Id);
        Assert.Equal(MatchWorkflowState.UserApproval, finished.State);
        Assert.Contains(MatchWorkflowState.MatchReady, finished.StateHistoryJson);
        Assert.Empty(await context.Db.ChatMessages.ToListAsync()); // the AI never connects anyone
    }

    [Fact]
    public async Task ApplyResult_WithoutMatches_EndsInSafeFailureWithReason()
    {
        await using var context = await Component4TestContext.CreateAsync();
        var (service, _) = Create(context);
        var need = await context.AddListingAsync(type: ListingType.INeed);
        var workflow = await StartedWorkflowAsync(context, service, need);

        await service.ApplyResultAsync(workflow.Id, new AiWorkflowResult
        {
            Outcome = MatchWorkflowOutcome.NeedsInfo,
            Reason = "Add a numeric quantity.",
        });

        var finished = await context.Db.MatchWorkflows.AsNoTracking().FirstAsync(w => w.Id == workflow.Id);
        Assert.Equal((MatchWorkflowState.SafeFailure, MatchWorkflowOutcome.NeedsInfo, "Add a numeric quantity."),
            (finished.State, finished.Outcome, finished.Reason));
        await Assert.ThrowsAsync<InvalidOperationException>(() => service.SearchCandidatesAsync(workflow.Id, ["Plastics"], 5));
    }

    [Fact]
    public async Task Connect_CreatesOneChatMessage_AndDismissIsRemembered()
    {
        await using var context = await Component4TestContext.CreateAsync();
        var (service, _) = Create(context);
        var need = await context.AddListingAsync(type: ListingType.INeed);
        var have = await context.AddListingAsync();
        var workflow = await StartedWorkflowAsync(context, service, need);
        await service.ApplyResultAsync(workflow.Id, new AiWorkflowResult { Outcome = MatchWorkflowOutcome.Matches, Matches = [Match(have.Id)] });

        var forBuyer = Assert.Single(await service.GetMineAsync(context.Buyer.Id));
        Assert.Equal(need.Id, forBuyer.MyListing.Id);
        Assert.Equal(have.Id, forBuyer.OtherListing.Id);
        Assert.Single(await service.GetMineAsync(context.Seller.Id)); // both owners see it
        Assert.Empty(await service.GetMineAsync(context.OtherSeller.Id));
        await Assert.ThrowsAsync<KeyNotFoundException>(() => service.ConnectAsync(context.OtherSeller.Id, forBuyer.Id));

        var connected = await service.ConnectAsync(context.Buyer.Id, forBuyer.Id);
        await service.ConnectAsync(context.Buyer.Id, forBuyer.Id); // repeat tap: no second message
        var message = await context.Db.ChatMessages.SingleAsync();
        Assert.Equal((have.Id, context.Buyer.Id, context.Seller.Id), (message.ListingId, message.SenderId, message.ReceiverId));
        Assert.Equal(context.Seller.Id, connected.OtherBusinessId);

        await service.DismissAsync(context.Seller.Id, forBuyer.Id);
        Assert.Empty(await service.GetMineAsync(context.Seller.Id));

        // A later workflow refreshes the evidence but doesn't resurrect the dismissal.
        await context.Db.MatchWorkflows.ExecuteUpdateAsync(w => w.SetProperty(x => x.CreatedAt, DateTime.UtcNow.AddHours(-1)));
        var rerun = await StartedWorkflowAsync(context, service, need);
        await service.ApplyResultAsync(rerun.Id, new AiWorkflowResult { Outcome = MatchWorkflowOutcome.Matches, Matches = [Match(have.Id)] });
        Assert.Empty(await service.GetMineAsync(context.Seller.Id));
        Assert.Single(await service.GetMineAsync(context.Buyer.Id));
    }

    [Fact]
    public async Task AdminAudit_ListsRunsNewestFirst_WithHistory()
    {
        await using var context = await Component4TestContext.CreateAsync();
        var (service, _) = Create(context);
        var need = await context.AddListingAsync(type: ListingType.INeed);
        var older = await StartedWorkflowAsync(context, service, need);
        await service.ApplyResultAsync(older.Id, new AiWorkflowResult { Outcome = MatchWorkflowOutcome.NoMatch, Reason = "None." });
        var newer = await StartedWorkflowAsync(context, service, need);

        var all = await service.GetWorkflowsAsync("all");
        Assert.Equal([newer.Id, older.Id], all.Select(w => w.Id));
        Assert.Equal("Buyer", all[0].OwnerName);
        Assert.Equal([older.Id], (await service.GetWorkflowsAsync(MatchWorkflowState.SafeFailure)).Select(w => w.Id));

        var details = await service.GetWorkflowAsync(older.Id);
        Assert.NotNull(details);
        Assert.Equal(2, details!.StateHistory.GetArrayLength()); // MATCHING, SAFE_FAILURE
        Assert.Null(await service.GetWorkflowAsync(Guid.NewGuid()));
    }

    [Fact]
    public async Task Activity_ShowsLatestCheckPerActivePost()
    {
        await using var context = await Component4TestContext.CreateAsync();
        var (service, _) = Create(context);
        var checkedPost = await context.AddListingAsync(type: ListingType.INeed);
        var neverChecked = await context.AddListingAsync(type: ListingType.INeed);
        var workflow = await StartedWorkflowAsync(context, service, checkedPost);
        await service.ApplyResultAsync(workflow.Id, new AiWorkflowResult
        {
            Outcome = MatchWorkflowOutcome.NoMatch,
            Reason = "No other users have matching I HAVE posts yet.",
        });

        var activity = await service.GetMyActivityAsync(context.Buyer.Id);

        var checkedRow = activity.Single(a => a.ListingId == checkedPost.Id);
        Assert.Equal((MatchWorkflowState.SafeFailure, "No other users have matching I HAVE posts yet."), (checkedRow.State, checkedRow.Reason));
        Assert.Null(activity.Single(a => a.ListingId == neverChecked.Id).State);
        Assert.Empty(await service.GetMyActivityAsync(context.OtherSeller.Id)); // only my own posts
    }

    [Fact]
    public async Task Activity_CountsMatchesFoundFromEitherSide()
    {
        await using var context = await Component4TestContext.CreateAsync();
        var (service, _) = Create(context);
        var need = await context.AddListingAsync(type: ListingType.INeed); // Buyer
        var have = await context.AddListingAsync();                         // Seller
        // The Buyer's check finds the Seller's post...
        var workflow = await StartedWorkflowAsync(context, service, need);
        await service.ApplyResultAsync(workflow.Id, new AiWorkflowResult { Outcome = MatchWorkflowOutcome.Matches, Matches = [Match(have.Id)] });

        // ...so the Seller's post shows the match too, though it was never checked itself.
        var sellerPost = Assert.Single(await service.GetMyActivityAsync(context.Seller.Id), a => a.ListingId == have.Id);
        Assert.Null(sellerPost.State);
        Assert.Equal(1, sellerPost.SuggestionCount);

        var suggestion = Assert.Single(await service.GetMineAsync(context.Seller.Id));
        await service.DismissAsync(context.Seller.Id, suggestion.Id);
        Assert.Equal(0, (await service.GetMyActivityAsync(context.Seller.Id)).Single(a => a.ListingId == have.Id).SuggestionCount);
        Assert.Equal(1, (await service.GetMyActivityAsync(context.Buyer.Id)).Single(a => a.ListingId == need.Id).SuggestionCount);
    }
}
