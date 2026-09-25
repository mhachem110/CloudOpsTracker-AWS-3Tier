using CloudOpsTracker.API.Data;
using Microsoft.EntityFrameworkCore;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers();

builder.Services.AddDbContext<CloudOpsDbContext>(options =>
    options.UseSqlServer(
        builder.Configuration.GetConnectionString("CloudOpsTrackerDb")));

var app = builder.Build();

app.UseHttpsRedirection();
app.MapControllers();

app.Run();
