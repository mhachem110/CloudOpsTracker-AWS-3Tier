using System.ComponentModel.DataAnnotations;

namespace CloudOpsTracker.Web.Models;

public class EditIncidentViewModel
{
    public int Id { get; set; }

    [Required, MaxLength(120)]
    public string Title { get; set; } = string.Empty;

    [MaxLength(1000)]
    public string? Description { get; set; }

    [Required]
    public string Priority { get; set; } = "Medium";

    [Required]
    public string Status { get; set; } = "Open";
}
