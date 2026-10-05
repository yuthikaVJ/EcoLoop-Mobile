using System.ComponentModel.DataAnnotations;

namespace EcoLoop.Api.DTOs;

public class BusinessVerificationRequestDto : BusinessProfileDto
{
    public string? OwnerName { get; set; }
    public string? OwnerEmail { get; set; }
}

public class BusinessVerificationSummaryDto
{
    public int Pending { get; set; }
    public int Verified { get; set; }
    public int Rejected { get; set; }
}

public class RejectBusinessRequest
{
    [Required(ErrorMessage = "A reason is required so the owner knows what to fix.")]
    [StringLength(500, MinimumLength = 3)]
    public string Reason { get; set; } = string.Empty;
}
