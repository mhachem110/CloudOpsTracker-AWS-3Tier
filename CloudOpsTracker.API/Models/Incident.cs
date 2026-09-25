using System.ComponentModel.DataAnnotations;

namespace CloudOpsTracker.API.Models;

public class Incident
{
    public int Id { get; set; }

    [Required, MaxLength(120)]
    public string Title { get; set; } = string.Empty;

    [MaxLength(1000)]
    public string? Description { get; set; }

    [Required, MaxLength(20)]
    public string Priority { get; set; } = "Medium";

    [Required, MaxLength(20)]
    public string Status { get; set; } = "Open";

    public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;
}
