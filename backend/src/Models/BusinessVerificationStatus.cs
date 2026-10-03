namespace EcoLoop.Api.Models;

// Values of Business.Status for Business Hub profiles.
public static class BusinessVerificationStatus
{
    public const string Unverified = "Unverified"; // awaiting admin review
    public const string Verified = "Verified";
    public const string Rejected = "Rejected";
}
