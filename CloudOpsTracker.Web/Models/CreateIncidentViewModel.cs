using System.ComponentModel.DataAnnotations;

namespace CloudOpsTracker.Web.Models;

public class CreateIncidentViewModel
{
    [Required, MaxLength(120)]
    public string Title { get; set; } = string.Empty;

    [MaxLength(1000)]
    public string? Description { get; set; }

    [Required, MaxLength(20), RegularExpression("Low|Medium|High|Critical")]
    public string Priority { get; set; } = "Medium";
}
