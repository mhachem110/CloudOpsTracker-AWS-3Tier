using Microsoft.AspNetCore.Mvc;

namespace CloudOpsTracker.API.Controllers;

[ApiController]
[Route("healthz")]
public class HealthController : ControllerBase
{
    [HttpGet]
    public IActionResult Get() => Ok(new { status = "healthy" });
}
