namespace EcoLoop.Api.Services;

// Uploaded files are stored as server-relative paths ("/uploads/..."), never as
// full URLs: a host baked into the database (e.g. the emulator's 10.0.2.2) breaks
// on every other device. Clients add their own server address when displaying.
public static class MediaPaths
{
    /// "/uploads/x.jpg" for both "/uploads/x.jpg" and "http://any-host:5252/uploads/x.jpg";
    /// anything that isn't one of our uploads is returned unchanged.
    public static string Normalize(string url)
    {
        var trimmed = url.Trim();
        if (Uri.TryCreate(trimmed, UriKind.Absolute, out var uri) &&
            (uri.Scheme == Uri.UriSchemeHttp || uri.Scheme == Uri.UriSchemeHttps) &&
            uri.AbsolutePath.StartsWith("/uploads/", StringComparison.Ordinal))
        {
            return uri.AbsolutePath;
        }
        return trimmed;
    }
}
