using Microsoft.AspNetCore.DataProtection;

var builder = WebApplication.CreateBuilder(args);

builder.Logging.ClearProviders();
builder.Logging.AddJsonConsole(options => options.UseUtcTimestamp = true);
builder.Services.Configure<Microsoft.AspNetCore.Builder.ForwardedHeadersOptions>(options =>
{
    options.ForwardedHeaders = Microsoft.AspNetCore.HttpOverrides.ForwardedHeaders.XForwardedProto;
    options.KnownProxies.Add(System.Net.IPAddress.Loopback);
});

builder.Services.AddControllersWithViews();
builder.Services.AddHttpClient();
builder.Services.AddHttpClient("readiness", client => client.Timeout = TimeSpan.FromSeconds(4));
var keyPath = builder.Configuration["DataProtection:ParameterPath"];
var dataProtection = builder.Services.AddDataProtection().SetApplicationName("CloudOpsTracker.Web");
if (!string.IsNullOrWhiteSpace(keyPath))
    dataProtection.PersistKeysToAWSSystemsManager(keyPath, options => options.KMSKeyId = "alias/aws/ssm");
else if (!builder.Environment.IsDevelopment())
    throw new InvalidOperationException("DataProtection:ParameterPath is required outside Development.");

var app = builder.Build();
app.UseForwardedHeaders();

if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Incidents/Error");
    app.UseHsts();
}

if (builder.Configuration.GetValue("UseHttpsRedirection", true))
{
    app.UseHttpsRedirection();
}

app.UseStaticFiles();
app.UseRouting();
app.UseAuthorization();

app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Incidents}/{action=Index}/{id?}");

app.Run();

public partial class Program { }
