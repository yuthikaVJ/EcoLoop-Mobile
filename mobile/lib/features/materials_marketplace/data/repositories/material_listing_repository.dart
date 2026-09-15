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

  Future<MaterialListing> createListing(Map<String, dynamic> requestData, {File? imageFile}) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse(baseUrl));
      
      // Add text fields
      requestData.forEach((key, value) {
        request.fields[key] = value.toString();
      });

      // Add file if it exists
      if (imageFile != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
        ));
      }

      final headers = await _apiClient.getAuthHeaders();
      request.headers.addAll(headers);

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 401) {
        // Retry logic for multipart
        final _authRepository = _apiClient; // Wait, we can't easily access it. I'll ignore retry for multipart for now or just handle it if it fails.
      }

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return MaterialListing.fromJson(data);
      } else {
        throw Exception('Failed to create listing: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error while creating listing: $e');
    }
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
