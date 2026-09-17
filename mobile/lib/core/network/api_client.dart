import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../features/auth/data/repositories/auth_repository.dart';

class ApiClient {
  final AuthRepository _authRepository;
  final String baseUrl;

  ApiClient(this._authRepository, {String? baseUrl}) 
      : baseUrl = baseUrl ?? 'http://10.0.2.2:5252';

  Future<Map<String, String>> getAuthHeaders() async {
    final token = await _authRepository.getSavedToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
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

  Future<http.Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    String url = _buildUrl(path, queryParameters);
    var response = await http.get(Uri.parse(url), headers: await getAuthHeaders());
    if (response.statusCode == 401) {
      final refreshed = await _authRepository.refreshToken();
      if (refreshed) {
        response = await http.get(Uri.parse(url), headers: await getAuthHeaders());
      }
    }
    return response;
  }

  Future<http.Response> post(String path, {Object? body}) async {
    String url = _buildUrl(path, null);
    var response = await http.post(
      Uri.parse(url), 
      headers: await getAuthHeaders(), 
      body: body
    );
    if (response.statusCode == 401) {
      final refreshed = await _authRepository.refreshToken();
      if (refreshed) {
        response = await http.post(
          Uri.parse(url), 
          headers: await getAuthHeaders(), 
          body: body
        );
      }
    }
    return response;
  }

  Future<http.Response> put(String path, {Object? body}) async {
    String url = _buildUrl(path, null);
    var response = await http.put(
      Uri.parse(url), 
      headers: await getAuthHeaders(), 
      body: body
    );
    if (response.statusCode == 401) {
      final refreshed = await _authRepository.refreshToken();
      if (refreshed) {
        response = await http.put(
          Uri.parse(url), 
          headers: await getAuthHeaders(), 
          body: body
        );
      }
    }
    return response;
  }

  Future<http.Response> patch(String path, {Object? body}) async {
    String url = _buildUrl(path, null);
    var response = await http.patch(
      Uri.parse(url), 
      headers: await getAuthHeaders(), 
      body: body
    );
    if (response.statusCode == 401) {
      final refreshed = await _authRepository.refreshToken();
      if (refreshed) {
        response = await http.patch(
          Uri.parse(url), 
          headers: await getAuthHeaders(), 
          body: body
        );
      }
    }
    return response;
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