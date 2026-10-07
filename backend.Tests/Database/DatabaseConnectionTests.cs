using Npgsql;

namespace Backend.Tests.Database;

public class DatabaseConnectionTests : IClassFixture<PostgreSqlFixture>
{
    private readonly PostgreSqlFixture _fixture;

    public DatabaseConnectionTests(PostgreSqlFixture fixture)
    {
        _fixture = fixture;
    }

    [Fact(DisplayName = "DB-01 CanConnectToPostgreSql")]
    public async Task CanConnectToPostgreSql()
    {
        await using var connection =
            new NpgsqlConnection(_fixture.ConnectionString);

        await connection.OpenAsync();

        Assert.Equal(
            System.Data.ConnectionState.Open,
            connection.State);
    }
}