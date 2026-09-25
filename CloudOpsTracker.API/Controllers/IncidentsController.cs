using CloudOpsTracker.API.Data;
using CloudOpsTracker.API.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace CloudOpsTracker.API.Controllers;

[ApiController]
[Route("api/incidents")]
public class IncidentsController : ControllerBase
{
    private readonly CloudOpsDbContext _db;

    public IncidentsController(CloudOpsDbContext db)
    {
        _db = db;
    }

    [HttpGet]
    public async Task<ActionResult<List<Incident>>> GetAll()
    {
        return await _db.Incidents
            .AsNoTracking()
            .OrderByDescending(i => i.CreatedAtUtc)
            .ToListAsync();
    }

    [HttpGet("{id:int}")]
    public async Task<ActionResult<Incident>> GetById(int id)
    {
        var incident = await _db.Incidents.AsNoTracking()
            .FirstOrDefaultAsync(i => i.Id == id);

        return incident is null ? NotFound() : Ok(incident);
    }

    [HttpPost]
    public async Task<ActionResult<Incident>> Create(CreateIncidentRequest request)
    {
        var incident = new Incident
        {
            Title = request.Title.Trim(),
            Description = request.Description?.Trim(),
            Priority = request.Priority,
            Status = "Open",
            CreatedAtUtc = DateTime.UtcNow
        };

        _db.Incidents.Add(incident);
        await _db.SaveChangesAsync();

        return CreatedAtAction(nameof(GetById), new { id = incident.Id }, incident);
    }

    [HttpPut("{id:int}")]
    public async Task<IActionResult> Update(int id, UpdateIncidentRequest request)
    {
        var incident = await _db.Incidents.FindAsync(id);
        if (incident is null) return NotFound();

        incident.Title = request.Title.Trim();
        incident.Description = request.Description?.Trim();
        incident.Priority = request.Priority;
        incident.Status = request.Status;

        await _db.SaveChangesAsync();
        return NoContent();
    }

    [HttpDelete("{id:int}")]
    public async Task<IActionResult> Delete(int id)
    {
        var incident = await _db.Incidents.FindAsync(id);
        if (incident is null) return NotFound();

        _db.Incidents.Remove(incident);
        await _db.SaveChangesAsync();
        return NoContent();
    }
}
