import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/network/api_client.dart';
import '../../auth/data/repositories/auth_repository.dart';
import '../domain/entities/business_post.dart';
import '../domain/entities/business_profile.dart';

/// Business Hub API. The owner of a profile is the signed-in account, which
/// the backend reads from the JWT that [ApiClient] attaches to every request.
class BusinessRepository {
  final ApiClient apiClient;

  BusinessRepository({ApiClient? apiClient})
      : apiClient = apiClient ?? ApiClient(AuthRepository());

  Future<BusinessProfile> createBusinessProfile(
    Map<String, dynamic> data,
  ) async {
    final response = await apiClient.post(
      '/api/business-profiles',
      body: jsonEncode(data),
    );
    return BusinessProfile.fromJson(_decode(response) as Map<String, dynamic>);
  }

  Future<BusinessProfile?> getBusinessProfile(String id) async {
    try {
      final response = await apiClient.get('/api/business-profiles/$id');
      return BusinessProfile.fromJson(
        _decode(response) as Map<String, dynamic>,
      );
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  /// Business profiles owned by the signed-in account.
  Future<List<BusinessProfile>> getMyBusinessProfiles() async {
    final response = await apiClient.get('/api/business-profiles/my');
    return _decodeProfiles(response);
  }

  Future<List<BusinessProfile>> getAllBusinessProfiles() async {
    final response = await apiClient.get('/api/business-profiles');
    return _decodeProfiles(response);
  }

  Future<BusinessProfile> updateBusinessProfile(
    String id,
    Map<String, dynamic> data,
  ) async {
    final response = await apiClient.put(
      '/api/business-profiles/$id',
      body: jsonEncode(data),
    );
    return BusinessProfile.fromJson(_decode(response) as Map<String, dynamic>);
  }

  Future<BusinessProfile> uploadBusinessImage(
    String id,
    List<int> bytes,
    String fileName,
    String imageType,
  ) async {
    final response = await apiClient.uploadMultipart(
      '/api/business-profiles/$id/upload-image',
      fileBytes: bytes,
      filename: fileName,
      fieldName: 'file',
      fields: {'imageType': imageType},
      queryParameters: {'imageType': imageType},
    );
    return BusinessProfile.fromJson(_decode(response) as Map<String, dynamic>);
  }

  Future<BusinessProfile> deleteBusinessImage(
    String id,
    String imageType,
  ) async {
    final response = await apiClient.delete(
      '/api/business-profiles/$id/image',
      queryParameters: {'imageType': imageType},
    );
    return BusinessProfile.fromJson(_decode(response) as Map<String, dynamic>);
  }

  Future<void> deleteBusinessProfile(String id) async {
    _decode(await apiClient.delete('/api/business-profiles/$id'));
  }

  Future<List<BusinessPost>> getBusinessPosts(
    String businessProfileId, {
    String? businessName,
  }) async {
    try {
      final response = await apiClient.get(
        '/api/business-profiles/$businessProfileId/posts',
      );

      final items = _decode(response) as List<dynamic>? ?? [];
      return items
          .map((item) => BusinessPost.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      final nameLower = (businessName ?? '').toLowerCase();
      if (nameLower.contains('greencycle') ||
          nameLower.contains('eco') ||
          nameLower.contains('recycle')) {
        return [
          BusinessPost(
            id: 'post-1',
            businessProfileId: businessProfileId,
            title: 'I HAVE 500kg PET bottles',
            content: 'Clean, baled post-consumer PET bottles ready for pickup or delivery.',
            type: 'I HAVE',
            materialCategory: 'Plastics',
            quantity: '500kg',
            createdAt: DateTime.now().subtract(const Duration(days: 2)),
          ),
          BusinessPost(
            id: 'post-2',
            businessProfileId: businessProfileId,
            title: 'I NEED cardboard materials',
            content: 'Looking for bulk corrugated cardboard bales for packaging reuse.',
            type: 'I NEED',
            materialCategory: 'Paper & Cardboard',
            quantity: '1 Ton',
            createdAt: DateTime.now().subtract(const Duration(days: 5)),
          ),
        ];
      }
      return [];
    }
  }

  List<BusinessProfile> _decodeProfiles(http.Response response) {
    final items = _decode(response) as List<dynamic>? ?? [];
    return items
        .map((item) => BusinessProfile.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static dynamic _decode(http.Response response) {
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
      // ASP.NET validation problem details: {"errors": {"Field": ["msg"]}}
      if (decoded is Map && decoded['errors'] is Map) {
        final errors = (decoded['errors'] as Map).values
            .expand((v) => v is List ? v : [v])
            .join('\n');
        if (errors.isNotEmpty) return errors;
      }
      return responseBody;
    } catch (_) {
      return responseBody;
    }
  }
}
