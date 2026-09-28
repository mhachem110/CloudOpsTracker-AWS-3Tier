using System.ComponentModel.DataAnnotations;

namespace CloudOpsTracker.API.Models;

public class UpdateIncidentRequest
{
    [Required, MaxLength(120)]
    public string Title { get; set; } = string.Empty;

    [MaxLength(1000)]
    public string? Description { get; set; }

    [Required, MaxLength(20), RegularExpression("Low|Medium|High|Critical")]
    public string Priority { get; set; } = "Medium";

    [Required, MaxLength(20), RegularExpression("Open|In Progress|Resolved|Closed")]
    public string Status { get; set; } = "Open";
}
