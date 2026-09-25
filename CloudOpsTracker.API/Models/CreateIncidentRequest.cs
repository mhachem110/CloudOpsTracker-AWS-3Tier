using System.ComponentModel.DataAnnotations;

namespace CloudOpsTracker.API.Models;

public class CreateIncidentRequest
{
    [Required, MaxLength(120)]
    public string Title { get; set; } = string.Empty;

    [MaxLength(1000)]
    public string? Description { get; set; }

    [Required]
    public string Priority { get; set; } = "Medium";
}
