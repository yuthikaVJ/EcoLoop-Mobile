using System.Net.Http.Json;
using EcoLoop.Api.DTOs;

namespace EcoLoop.Api.Services.Matching;

// Calls the internal Python service. Only the backend knows its address and key;
// Flutter and React never reach it (spec section 3).
public class AiMatchingClient(HttpClient client, IConfiguration configuration)
{
    public async Task<AiWorkflowResult> RunAsync(Guid workflowId, CancellationToken cancellationToken)
    {
        var baseUrl = configuration["AiService:BaseUrl"];
        var key = configuration["AiService:ApiKey"];
        if (string.IsNullOrWhiteSpace(baseUrl) || string.IsNullOrWhiteSpace(key))
            throw new InvalidOperationException("AiService:BaseUrl and AiService:ApiKey must be configured.");

        using var request = new HttpRequestMessage(HttpMethod.Post, $"{baseUrl.TrimEnd('/')}/workflows/run")
        {
            Content = JsonContent.Create(new { workflowId = workflowId.ToString() }),
        };
        request.Headers.Add("X-AI-Service-Key", key);
        using var response = await client.SendAsync(request, cancellationToken);
        response.EnsureSuccessStatusCode();
        return await response.Content.ReadFromJsonAsync<AiWorkflowResult>(cancellationToken)
            ?? throw new InvalidOperationException("The AI service returned an empty result.");
    }
}
