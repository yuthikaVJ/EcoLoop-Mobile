import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/material_listing.dart';

class MaterialListingRepository {
  static const String baseUrl = 'http://10.0.2.2:5252/api/MaterialListings';
  final ApiClient _apiClient;

  MaterialListingRepository(this._apiClient);

  Future<List<MaterialListing>> getListings({
    String? search,
    String? category,
    int? type,
    int page = 1,
    int pageSize = 100,
  }) async {
    try {
      final queryParams = {
        if (search != null && search.isNotEmpty) 'search': search,
        if (category != null && category.isNotEmpty && category != 'ALL') 'category': category,
        if (type != null) 'type': type.toString(),
        'page': page.toString(),
        'pageSize': pageSize.toString(),
      };

      final uri = Uri.parse(baseUrl).replace(queryParameters: queryParams);
      final response = await _apiClient.get(uri.toString());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> items = data['items'];
        return items.map((json) => MaterialListing.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load listings: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error while fetching listings: $e');
    }
  }

  Future<MaterialListing> getListingById(String id) async {
    try {
      final uri = Uri.parse('$baseUrl/$id');
      final response = await _apiClient.get(uri.toString());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return MaterialListing.fromJson(data);
      } else {
        throw Exception('Failed to load listing details: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error while fetching listing details: $e');
    }
  }

  Future<MaterialListing> createListing(
    Map<String, dynamic> requestData, {
    List<File> imageFiles = const [],
  }) async {
    // A multipart request can only be sent once, so build a fresh one per try.
    Future<http.Response> send() async {
      final request = http.MultipartRequest('POST', Uri.parse(baseUrl));
      requestData.forEach((key, value) {
        request.fields[key] = value.toString();
      });
      for (final file in imageFiles) {
        request.files.add(await http.MultipartFile.fromPath('images', file.path));
      }
      request.headers.addAll(await _apiClient.getAuthHeaders());
      return http.Response.fromStream(await request.send());
    }

    try {
      var response = await send();
      if (response.statusCode == 401 && await _apiClient.refreshToken()) {
        response = await send();
      }

      if (response.statusCode == 201) {
        return MaterialListing.fromJson(jsonDecode(response.body));
      }
      throw Exception('Failed to create listing: ${response.body}');
    } catch (e) {
      throw Exception('Network error while creating listing: $e');
    }
  }

  Future<MaterialListing> updateListing(String id, Map<String, dynamic> requestData) async {
    try {
      final response = await _apiClient.put(
        '$baseUrl/$id',
        body: jsonEncode(requestData),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return MaterialListing.fromJson(data);
      } else {
        throw Exception('Failed to update listing: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error while updating listing: $e');
    }
  }

  /// Uploads extra photos for an existing listing (multipart "images" fields).
  Future<MaterialListing> addImages(String id, List<File> imageFiles) async {
    Future<http.Response> send() async {
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/$id/images'));
      for (final file in imageFiles) {
        request.files.add(await http.MultipartFile.fromPath('images', file.path));
      }
      request.headers.addAll(await _apiClient.getAuthHeaders());
      return http.Response.fromStream(await request.send());
    }

    var response = await send();
    if (response.statusCode == 401 && await _apiClient.refreshToken()) {
      response = await send();
    }
    if (response.statusCode == 200) {
      return MaterialListing.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to add photos: ${response.body}');
  }

  Future<bool> changeStatus(String id, int newStatus) async {
    try {
      final response = await _apiClient.patch(
        '$baseUrl/$id/status',
        body: jsonEncode(newStatus),
      );

      return response.statusCode == 204;
    } catch (e) {
      throw Exception('Network error while changing status: $e');
    }
  }
}
