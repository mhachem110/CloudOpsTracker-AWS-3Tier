using CloudOpsTracker.API.Data;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace CloudOpsTracker.API.Controllers;

[ApiController]
[ResponseCache(NoStore = true, Location = ResponseCacheLocation.None)]
public class HealthController : ControllerBase
{
    [HttpGet("health/live")]
    public IActionResult Live() => Ok(new { status = "healthy" });

    [HttpGet("health/ready")]
    [HttpGet("healthz")]
    public async Task<IActionResult> Ready([FromServices] CloudOpsDbContext db)
    {
        using var timeout = CancellationTokenSource.CreateLinkedTokenSource(HttpContext.RequestAborted);
        timeout.CancelAfter(TimeSpan.FromSeconds(3));
        try
        {
            // Checks connectivity and the expected schema without returning incident data.
            await db.Incidents.AsNoTracking().AnyAsync(timeout.Token);
            return Ok(new { status = "ready" });
        }
        catch (Exception)
        {
            return StatusCode(503, new { status = "unavailable" });
        }
    }
}
