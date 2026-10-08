import 'dart:convert';

/// Shared connection settings and the signed-in business for all features.
class AppConfig {
  /// The ONE place to change the backend address. Override at build time with
  /// --dart-define=ECOLOOP_SERVER_URL=https://your-host (no trailing slash).
  /// Default is a backend running on this PC, reached from the Android emulator
  /// (10.0.2.2 = the PC's localhost); the hosted backend is http://52.74.2.76:5252.
  static const serverUrl = String.fromEnvironment(
    'ECOLOOP_SERVER_URL',
    defaultValue: 'http://10.0.2.2:5252',
  );

  static const apiBaseUrl = '$serverUrl/api';
  static const chatHubUrl = '$serverUrl/chatHub';

  // Hosts older uploads were saved with; rewritten to [serverUrl] for display.
  static final _legacyHost =
      RegExp(r'^https?://(10\.0\.2\.2|localhost|127\.0\.0\.1)(:\d+)?');

  /// Full URL for an uploaded file: resolves server paths (/uploads/...) and
  /// rewrites links saved with the emulator's local address.
  static String? mediaUrl(String? url) {
    if (url == null || url.trim().isEmpty) return null;
    final trimmed = url.trim();
    if (_legacyHost.hasMatch(trimmed)) {
      return trimmed.replaceFirst(_legacyHost, serverUrl);
    }
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    return trimmed.startsWith('/') ? '$serverUrl$trimmed' : '$serverUrl/$trimmed';
  }

  static const _nameIdentifierClaim =
      'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier';

  static String _currentBusinessId = '';

  /// Business ID of the signed-in user, taken from the JWT the backend issues
  /// (its NameIdentifier claim). Empty when nobody is signed in.
  static String get currentBusinessId => _currentBusinessId;

  /// Called by the auth flow whenever the access token is loaded or changes.
  static void setSessionToken(String? token) {
    _currentBusinessId = businessIdFromToken(token) ?? '';
  }

  static String? businessIdFromToken(String? token) {
    final parts = token?.split('.');
    if (parts == null || parts.length != 3) return null;
    try {
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      if (payload is! Map) return null;
      final id = payload[_nameIdentifierClaim] ?? payload['nameid'];
      return id is String && id.isNotEmpty ? id : null;
    } on FormatException {
      return null;
    }
  }
}
