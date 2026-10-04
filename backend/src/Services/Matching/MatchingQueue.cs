using System.Threading.Channels;

namespace EcoLoop.Api.Services.Matching;

public interface IMatchingQueue
{
    void Enqueue(Guid workflowId);
    IAsyncEnumerable<Guid> ReadAllAsync(CancellationToken cancellationToken);
}

// In-memory queue: posting stays instant while workflows run in the background.
public class MatchingQueue : IMatchingQueue
{
    private readonly Channel<Guid> _channel = Channel.CreateUnbounded<Guid>();

    public void Enqueue(Guid workflowId) => _channel.Writer.TryWrite(workflowId);

    public IAsyncEnumerable<Guid> ReadAllAsync(CancellationToken cancellationToken) =>
        _channel.Reader.ReadAllAsync(cancellationToken);
}
