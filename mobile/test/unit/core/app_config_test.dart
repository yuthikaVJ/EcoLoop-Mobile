// Core configuration (lib/core/config/app_config.dart): one server address for
// the whole app, and media links that work on real phones, not just the emulator.
import 'package:flutter_test/flutter_test.dart';

import 'package:eco_loop/core/config/app_config.dart';

void main() {
  const server = AppConfig.serverUrl;

  group('server address', () {
    test('API and chat hub are built from the single server URL', () {
      expect(AppConfig.apiBaseUrl, '$server/api');
      expect(AppConfig.chatHubUrl, '$server/chatHub');
      expect(server.endsWith('/'), isFalse);
    });
  });

  group('mediaUrl', () {
    test('turns a server path into a full URL', () {
      expect(AppConfig.mediaUrl('/uploads/material_listings/a.jpg'), '$server/uploads/material_listings/a.jpg');
      expect(AppConfig.mediaUrl('uploads/a.jpg'), '$server/uploads/a.jpg');
    });

    test('rewrites links saved with the emulator or localhost address', () {
      for (final legacy in [
        'http://10.0.2.2:5252/uploads/a.jpg',
        'http://localhost:5252/uploads/a.jpg',
        'http://127.0.0.1/uploads/a.jpg',
      ]) {
        expect(AppConfig.mediaUrl(legacy), '$server/uploads/a.jpg', reason: legacy);
      }
    });

    test('leaves other full URLs and data images alone', () {
      expect(AppConfig.mediaUrl('https://lh3.googleusercontent.com/p.jpg'), 'https://lh3.googleusercontent.com/p.jpg');
    });

    test('returns null for missing links', () {
      expect(AppConfig.mediaUrl(null), isNull);
      expect(AppConfig.mediaUrl('   '), isNull);
    });
  });
}
