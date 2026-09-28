using Microsoft.AspNetCore.DataProtection;
using Microsoft.AspNetCore.Mvc;

namespace CloudOpsTracker.Web.Controllers;

[ResponseCache(NoStore = true, Location = ResponseCacheLocation.None)]
public class HealthController : ControllerBase
{
    [HttpGet("health/live")]
    public IActionResult Live() => Ok(new { status = "healthy" });

    [HttpGet("health/ready")]
    public async Task<IActionResult> Ready([FromServices] IHttpClientFactory clients,
        [FromServices] IConfiguration configuration, [FromServices] IDataProtectionProvider keys)
    {
        try
        {
            var protector = keys.CreateProtector("Readiness");
            if (protector.Unprotect(protector.Protect("ready")) != "ready")
                return StatusCode(503);
            var address = new Uri(new Uri(configuration["ApiBaseUrl"]!), "/health/ready");
            using var response = await clients.CreateClient("readiness").GetAsync(address, HttpContext.RequestAborted);
            return response.IsSuccessStatusCode ? Ok(new { status = "ready" })
                : StatusCode(503, new { status = "unavailable" });
        }
        catch (Exception)
        {
            return StatusCode(503, new { status = "unavailable" });
        }
    }
}
