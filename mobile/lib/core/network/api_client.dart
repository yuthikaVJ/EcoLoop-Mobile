import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiClient {
  final String baseUrl;
  final http.Client _client;

  static String get defaultBaseUrl {
    if (kIsWeb) return 'http://localhost:5000';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:5000';
      default:
        return 'http://localhost:5000';
    }
  }

  ApiClient({
    String? baseUrl,
    http.Client? client,
  })  : baseUrl = baseUrl ?? defaultBaseUrl,
        _client = client ?? http.Client();

  String? resolveUrl(String? pathOrUrl) {
    if (pathOrUrl == null || pathOrUrl.trim().isEmpty) return null;
    final trimmed = pathOrUrl.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    if (trimmed.startsWith('/')) {
      return '$baseUrl$trimmed';
    }
    return '$baseUrl/$trimmed';
  }

  Future<dynamic> get(
    String path, {
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse('$baseUrl$path').replace(
      queryParameters: queryParameters,
    );
    final response = await _client.get(uri, headers: headers);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        statusCode: response.statusCode,
        message: _extractErrorMessage(response.body),
      );
    }

    if (response.body.isEmpty) return null;
    return jsonDecode(response.body);
  }

  Future<dynamic> post(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final combinedHeaders = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      ...?headers,
    };

    final response = await _client.post(
      uri,
      headers: combinedHeaders,
      body: body != null ? jsonEncode(body) : null,
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        statusCode: response.statusCode,
        message: _extractErrorMessage(response.body),
      );
    }

    if (response.body.isEmpty) return null;
    return jsonDecode(response.body);
  }

  Future<dynamic> put(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final combinedHeaders = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      ...?headers,
    };

    final response = await _client.put(
      uri,
      headers: combinedHeaders,
      body: body != null ? jsonEncode(body) : null,
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        statusCode: response.statusCode,
        message: _extractErrorMessage(response.body),
      );
    }

    if (response.body.isEmpty) return null;
    return jsonDecode(response.body);
  }

  Future<dynamic> delete(
    String path, {
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse('$baseUrl$path').replace(
      queryParameters: queryParameters,
    );
    final response = await _client.delete(uri, headers: headers);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        statusCode: response.statusCode,
        message: _extractErrorMessage(response.body),
      );
    }

    if (response.body.isEmpty) return null;
    return jsonDecode(response.body);
  }

  Future<dynamic> uploadMultipart(
    String path, {
    required List<int> fileBytes,
    required String filename,
    required String fieldName,
    Map<String, String>? fields,
    Map<String, String>? headers,
    Map<String, String>? queryParameters,
  }) async {
    final uri = Uri.parse('$baseUrl$path').replace(
      queryParameters: queryParameters,
    );
    final request = http.MultipartRequest('POST', uri);

    if (headers != null) {
      request.headers.addAll(headers);
    }
    if (fields != null) {
      request.fields.addAll(fields);
    }

    request.files.add(
      http.MultipartFile.fromBytes(
        fieldName,
        fileBytes,
        filename: filename,
      ),
    );

    final streamedResponse = await _client.send(request);
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        statusCode: response.statusCode,
        message: _extractErrorMessage(response.body),
      );
    }

    if (response.body.isEmpty) return null;
    return jsonDecode(response.body);
  }

  static String _extractErrorMessage(String responseBody) {
    if (responseBody.isEmpty) return 'Request failed.';
    try {
      final decoded = jsonDecode(responseBody);
      if (decoded is Map && decoded.containsKey('message')) {
        return decoded['message'].toString();
      }
      return responseBody;
    } catch (_) {
      return responseBody;
    }
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