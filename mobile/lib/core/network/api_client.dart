import 'package:http/http.dart' as http;
import '../../features/auth/data/repositories/auth_repository.dart';
import '../config/app_config.dart';

class ApiClient {
  final AuthRepository _authRepository;
  final String baseUrl;
  // Injected by tests (e.g. a fake EcoLoop server); null in the app.
  final http.Client? _client;

  ApiClient(this._authRepository, {String? baseUrl, http.Client? client})
      : baseUrl = baseUrl ?? AppConfig.serverUrl,
        _client = client;

  Future<Map<String, String>> getAuthHeaders() async {
    final token = await _authRepository.getSavedToken();
    return {
      'Content-Type': 'application/json',
      'Cache-Control': 'no-cache',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<bool> refreshToken() async {
    return await _authRepository.refreshToken();
  }

  String _buildUrl(String path, Map<String, dynamic>? queryParameters) {
    String url = path.startsWith('http') ? path : '$baseUrl$path';
    if (queryParameters != null && queryParameters.isNotEmpty) {
      final uri = Uri.parse(url).replace(
        queryParameters: queryParameters.map((k, v) => MapEntry(k, v.toString())),
      );
      return uri.toString();
    }
    return url;
  }

  /// Runs [call] with the injected client, or a short-lived default one.
  Future<T> _use<T>(Future<T> Function(http.Client client) call) async {
    final injected = _client;
    if (injected != null) return call(injected);
    final client = http.Client();
    try {
      return await call(client);
    } finally {
      client.close();
    }
  }

  /// Sends a request built by [makeRequest]; on 401 refreshes the session once
  /// and sends a freshly built copy (a request body can only be sent once).
  Future<http.Response> _sendWithRefresh(Future<http.BaseRequest> Function() makeRequest) async {
    var response = await send(await makeRequest());
    if (response.statusCode == 401 && await _authRepository.refreshToken()) {
      response = await send(await makeRequest());
    }
    return response;
  }

  /// Sends a prepared request (e.g. a multipart upload) through this client.
  Future<http.Response> send(http.BaseRequest request) =>
      _use((client) async => http.Response.fromStream(await client.send(request)));

  Future<http.Response> _json(String method, String url, {Object? body}) => _sendWithRefresh(() async {
        final request = http.Request(method, Uri.parse(url))..headers.addAll(await getAuthHeaders());
        if (body is String) request.body = body;
        return request;
      });

  Future<http.Response> get(String path, {Map<String, dynamic>? queryParameters}) =>
      _json('GET', _buildUrl(path, queryParameters));

  Future<http.Response> post(String path, {Object? body}) => _json('POST', _buildUrl(path, null), body: body);

  Future<http.Response> put(String path, {Object? body}) => _json('PUT', _buildUrl(path, null), body: body);

  Future<http.Response> patch(String path, {Object? body}) => _json('PATCH', _buildUrl(path, null), body: body);

  Future<http.Response> delete(String path, {Map<String, dynamic>? queryParameters}) =>
      _json('DELETE', _buildUrl(path, queryParameters));

  /// Sends one file as multipart/form-data with the signed-in user's token.
  Future<http.Response> uploadMultipart(
    String path, {
    required List<int> fileBytes,
    required String filename,
    required String fieldName,
    Map<String, String>? fields,
    Map<String, dynamic>? queryParameters,
  }) {
    final url = _buildUrl(path, queryParameters);
    return _sendWithRefresh(() async {
      final request = http.MultipartRequest('POST', Uri.parse(url));
      final headers = await getAuthHeaders()..remove('Content-Type');
      request.headers.addAll(headers);
      if (fields != null) request.fields.addAll(fields);
      request.files.add(
        http.MultipartFile.fromBytes(fieldName, fileBytes, filename: filename),
      );
      return request;
    });
  }

  /// Turns a server-relative path such as `/uploads/...` into a full URL.
  String? resolveUrl(String? pathOrUrl) {
    return AppConfig.mediaUrl(pathOrUrl);
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;

  const ApiException({
    required this.statusCode,
    required this.message,
  });

  @override
  String toString() => 'ApiException ($statusCode): $message';
}
