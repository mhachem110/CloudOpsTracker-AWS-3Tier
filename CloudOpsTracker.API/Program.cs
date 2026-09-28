using CloudOpsTracker.API.Data;
using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;

var migrateOnly = args.Contains("--migrate-only");
var builder = WebApplication.CreateBuilder(args.Where(a => a != "--migrate-only").ToArray());

builder.Logging.ClearProviders();
builder.Logging.AddJsonConsole(options => options.UseUtcTimestamp = true);
builder.Services.Configure<Microsoft.AspNetCore.Builder.ForwardedHeadersOptions>(options =>
{
    options.ForwardedHeaders = Microsoft.AspNetCore.HttpOverrides.ForwardedHeaders.XForwardedProto;
    options.KnownProxies.Add(System.Net.IPAddress.Loopback);
});

builder.Services.AddControllers();

var connectionString =
    builder.Configuration.GetConnectionString("CloudOpsTrackerDb");

if (string.IsNullOrWhiteSpace(connectionString))
{
    var dbHost = builder.Configuration["Database:Host"]
        ?? throw new InvalidOperationException("Database:Host is required.");

    var dbName = builder.Configuration["Database:Name"] ?? "CloudOpsTrackerDb";

    var dbUser = builder.Configuration["Database:Username"]
        ?? throw new InvalidOperationException("Database:Username is required.");

    var dbPassword = builder.Configuration["Database:Password"]
        ?? throw new InvalidOperationException("Database:Password is required.");

    var dbPort = builder.Configuration.GetValue("Database:Port", 1433);

    var sqlBuilder = new SqlConnectionStringBuilder
    {
        DataSource = $"{dbHost},{dbPort}",
        InitialCatalog = dbName,
        UserID = dbUser,
        Password = dbPassword,
        Encrypt = true,
        TrustServerCertificate = false,
        ConnectTimeout = 30
    };

    connectionString = sqlBuilder.ConnectionString;
}

builder.Services.AddDbContext<CloudOpsDbContext>(options =>
    options.UseSqlServer(connectionString));

var app = builder.Build();
app.UseForwardedHeaders();

if (builder.Configuration.GetValue("UseHttpsRedirection", true))
{
    app.UseHttpsRedirection();
}

app.MapControllers();

// Run once on the image source, before the readiness gate and ASG rollout.
if (migrateOnly)
{
    using var scope = app.Services.CreateScope();
    var db = scope.ServiceProvider.GetRequiredService<CloudOpsDbContext>();
    await db.Database.MigrateAsync();
    return;
}

app.Run();

public partial class Program { }
