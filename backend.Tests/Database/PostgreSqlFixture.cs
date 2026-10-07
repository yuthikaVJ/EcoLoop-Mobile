using Npgsql;
using EcoLoop.Api.Data;
using Microsoft.EntityFrameworkCore;
using Testcontainers.PostgreSql;

namespace Backend.Tests.Database;

public class PostgreSqlFixture : IAsyncLifetime
{
    private readonly PostgreSqlContainer _postgres = new PostgreSqlBuilder()
        .WithDatabase("testdb")
        .WithUsername("testuser")
        .WithPassword("testpassword")
        .Build();

    public string ConnectionString => _postgres.GetConnectionString();

    protected NpgsqlConnection CreateConnection() =>
        new(ConnectionString);

    public async Task InitializeAsync()
    {
        await _postgres.StartAsync();

        var options = new DbContextOptionsBuilder<EcoLoopDbContext>()
            .UseNpgsql(ConnectionString)
            .Options;

        await using var context = new EcoLoopDbContext(options);
        await context.Database.MigrateAsync();
    }

    public async Task DisposeAsync()
    {
        await _postgres.DisposeAsync();
    }
}