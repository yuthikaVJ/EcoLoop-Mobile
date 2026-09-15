import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../features/auth/data/repositories/auth_repository.dart';

class ApiClient {
  final AuthRepository _authRepository;

  ApiClient(this._authRepository);

  Future<Map<String, String>> getAuthHeaders() async {
    final token = await _authRepository.getSavedToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<http.Response> get(String url) async {
    var response = await http.get(Uri.parse(url), headers: await getAuthHeaders());
    if (response.statusCode == 401) {
      final refreshed = await _authRepository.refreshToken();
      if (refreshed) {
        response = await http.get(Uri.parse(url), headers: await getAuthHeaders());
      }
    }
    return response;
  }

  Future<http.Response> post(String url, {Object? body}) async {
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

  Future<http.Response> put(String url, {Object? body}) async {
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

  Future<http.Response> patch(String url, {Object? body}) async {
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
