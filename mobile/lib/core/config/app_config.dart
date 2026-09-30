/// Shared connection and development identity for all marketplace features.
/// Replace the business ID with authenticated session claims when auth lands.
class AppConfig {
  static const apiBaseUrl = String.fromEnvironment(
    'ECOLOOP_API_URL',
    defaultValue: 'http://10.0.2.2:5252/api',
  );
  static const currentBusinessId = String.fromEnvironment(
    'ECOLOOP_BUSINESS_ID',
    defaultValue: '22222222-2222-2222-2222-222222222222',
  );
}
