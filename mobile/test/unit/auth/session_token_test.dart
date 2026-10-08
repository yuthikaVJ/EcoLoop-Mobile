// Auth session (lib/core/config/app_config.dart): the signed-in business comes
// from the JWT the backend issues after Google sign-in.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:eco_loop/core/config/app_config.dart';

String jwt(Map<String, dynamic> claims) {
  String part(Object value) => base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  return '${part({'alg': 'HS256', 'typ': 'JWT'})}.${part(claims)}.signature';
}

void main() {
  const nameIdentifier = 'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier';

  tearDown(() => AppConfig.setSessionToken(null));

  test('reads the business id from the .NET name-identifier claim', () {
    expect(AppConfig.businessIdFromToken(jwt({nameIdentifier: 'biz-123'})), 'biz-123');
  });

  test('also accepts the short "nameid" claim', () {
    expect(AppConfig.businessIdFromToken(jwt({'nameid': 'biz-456'})), 'biz-456');
  });

  test('signing in and out updates the current business', () {
    AppConfig.setSessionToken(jwt({nameIdentifier: 'biz-123'}));
    expect(AppConfig.currentBusinessId, 'biz-123');

    AppConfig.setSessionToken(null);
    expect(AppConfig.currentBusinessId, isEmpty);
  });

  test('malformed tokens give no business', () {
    for (final token in [null, '', 'abc', 'a.b', 'a.!!!.c', jwt({'other': 'x'}), jwt({nameIdentifier: ''})]) {
      expect(AppConfig.businessIdFromToken(token), isNull, reason: '$token');
    }
  });
}
