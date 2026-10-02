import 'dart:convert';

/// Shared connection settings and the signed-in business for all features.
class AppConfig {
  static const apiBaseUrl = String.fromEnvironment(
    'ECOLOOP_API_URL',
    defaultValue: 'http://10.0.2.2:5252/api',
  );

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
