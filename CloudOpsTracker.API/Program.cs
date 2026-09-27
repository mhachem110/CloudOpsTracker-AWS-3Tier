using CloudOpsTracker.API.Data;
using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;

var builder = WebApplication.CreateBuilder(args);

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

if (builder.Configuration.GetValue("UseHttpsRedirection", true))
{
    app.UseHttpsRedirection();
}

app.MapControllers();

// Training-project convenience: apply the existing EF Core migration when the
// API starts. In a larger production system this would normally be a separate
// controlled migration job.
using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<CloudOpsDbContext>();
    await db.Database.MigrateAsync();
}

app.Run();
