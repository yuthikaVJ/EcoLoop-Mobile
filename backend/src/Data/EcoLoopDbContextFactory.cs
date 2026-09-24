using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;

namespace EcoLoop.Api.Data;

// Schema tooling must not start the API or execute its demo-data seeding.
public class EcoLoopDbContextFactory : IDesignTimeDbContextFactory<EcoLoopDbContext>
{
    public EcoLoopDbContext CreateDbContext(string[] args)
    {
        var configuration = new ConfigurationBuilder().SetBasePath(Directory.GetCurrentDirectory())
            .AddJsonFile("appsettings.json", optional: true).AddEnvironmentVariables().Build();
        var connection = configuration.GetConnectionString("DefaultConnection")
            ?? "Host=localhost;Database=ecoloop;Username=postgres";
        return new EcoLoopDbContext(new DbContextOptionsBuilder<EcoLoopDbContext>().UseNpgsql(connection).Options);
    }
}
