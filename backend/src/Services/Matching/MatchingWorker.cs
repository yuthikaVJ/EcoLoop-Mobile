namespace EcoLoop.Api.Services.Matching;

// Runs queued workflows one at a time (keeps within the Gemini rate limits).
public class MatchingWorker(IServiceScopeFactory scopes, IMatchingQueue queue, ILogger<MatchingWorker> logger) : BackgroundService
{
    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        using (var scope = scopes.CreateScope())
        {
            try
            {
                await scope.ServiceProvider.GetRequiredService<MatchingService>().RecoverInterruptedAsync();
            }
            catch (Exception ex)
            {
                logger.LogWarning(ex, "Could not recover interrupted matching workflows.");
            }
        }

        await foreach (var workflowId in queue.ReadAllAsync(stoppingToken))
        {
            using var scope = scopes.CreateScope();
            var matching = scope.ServiceProvider.GetRequiredService<MatchingService>();
            try
            {
                var result = await scope.ServiceProvider.GetRequiredService<AiMatchingClient>().RunAsync(workflowId, stoppingToken);
                await matching.ApplyResultAsync(workflowId, result);
            }
            catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested)
            {
                return;
            }
            catch (Exception ex)
            {
                logger.LogWarning(ex, "Matching workflow {WorkflowId} failed.", workflowId);
                await matching.FailAsync(workflowId, "The AI matching service is unavailable. Try again later.");
            }
        }
    }
}
