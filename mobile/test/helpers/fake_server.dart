import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// A fake EcoLoop backend for API-integration tests. The app's real
/// repositories and ApiClient run unchanged; only the HTTP layer is replaced
/// (http.runWithClient), so every request can be inspected.
class FakeServer {
  final List<http.Request> requests = [];
  final Map<String, http.Response Function(http.Request)> _routes = {};

  /// Registers an answer for "METHOD /path" (path without the query string).
  void on(String method, String path, http.Response Function(http.Request request) handler) {
    _routes['$method $path'] = handler;
  }

  void json(String method, String path, Object body, {int status = 200}) =>
      on(method, path, (_) => http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json'}));

  /// Runs [body] with every http call answered by this server.
  Future<T> run<T>(Future<T> Function() body) => http.runWithClient(
        body,
        () => MockClient((request) async {
          requests.add(request);
          final handler = _routes['${request.method} ${request.url.path}'];
          return handler?.call(request) ?? http.Response('{"message":"No route"}', 404);
        }),
      );

  http.Request last(String method, String path) =>
      requests.lastWhere((r) => r.method == method && r.url.path == path);
}

/// Pretends a user is signed in (the tokens AuthRepository reads).
void signIn({String accessToken = 'access-1', String refreshToken = 'refresh-1'}) {
  FlutterSecureStorage.setMockInitialValues({'access_token': accessToken, 'refresh_token': refreshToken});
}
