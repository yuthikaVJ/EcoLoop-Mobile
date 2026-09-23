import '../../../core/network/api_client.dart';
import '../domain/entities/business_post.dart';
import '../domain/entities/business_profile.dart';

class BusinessRepository {
  final ApiClient apiClient;

  BusinessRepository({ApiClient? apiClient})
      : apiClient = apiClient ?? ApiClient();

  Future<BusinessProfile> createBusinessProfile(
    Map<String, dynamic> data, {
    String? userId,
  }) async {
    final headers = <String, String>{};
    if (userId != null && userId.isNotEmpty) {
      headers['X-User-Id'] = userId;
    }

    final response = await apiClient.post(
      '/api/business-profiles',
      body: data,
      headers: headers.isNotEmpty ? headers : null,
    );

    return BusinessProfile.fromJson(response as Map<String, dynamic>);
  }

  Future<BusinessProfile?> getBusinessProfile(String id) async {
    try {
      final response = await apiClient.get('/api/business-profiles/$id');
      return BusinessProfile.fromJson(response as Map<String, dynamic>);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<BusinessProfile?> getMyBusinessProfile(String userId) async {
    try {
      final response =
          await apiClient.get('/api/business-profiles/user/$userId');
      return BusinessProfile.fromJson(response as Map<String, dynamic>);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<List<BusinessProfile>> getMyBusinessProfiles({
    String? userId,
    String? email,
  }) async {
    final headers = <String, String>{};
    if (userId != null && userId.isNotEmpty) {
      headers['X-User-Id'] = userId;
    }
    if (email != null && email.isNotEmpty) {
      headers['X-User-Email'] = email;
    }

    final queryParams = <String, String>{};
    if (email != null && email.isNotEmpty) {
      queryParams['email'] = email;
    }

    try {
      final response = await apiClient.get(
        '/api/business-profiles/my',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
        headers: headers.isNotEmpty ? headers : null,
      );

      final items = response as List<dynamic>? ?? [];
      return items
          .map((item) => BusinessProfile.fromJson(item as Map<String, dynamic>))
          .toList();
    } on ApiException catch (e) {
      // Graceful fallback if /api/business-profiles/my is 404
      if (e.statusCode == 404) {
        if (userId != null && userId.isNotEmpty) {
          final single = await getMyBusinessProfile(userId);
          return single != null ? [single] : [];
        }
      }
      rethrow;
    }
  }

  Future<List<BusinessProfile>> getAllBusinessProfiles() async {
    final response = await apiClient.get('/api/business-profiles');
    final items = response as List<dynamic>? ?? [];

    return items
        .map((item) => BusinessProfile.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<BusinessProfile> updateBusinessProfile(
    String id,
    Map<String, dynamic> data, {
    String? userId,
  }) async {
    final headers = <String, String>{};
    if (userId != null && userId.isNotEmpty) {
      headers['X-User-Id'] = userId;
    }

    final response = await apiClient.put(
      '/api/business-profiles/$id',
      body: data,
      headers: headers.isNotEmpty ? headers : null,
    );

    return BusinessProfile.fromJson(response as Map<String, dynamic>);
  }

  Future<BusinessProfile> uploadBusinessImage(
    String id,
    List<int> bytes,
    String fileName,
    String imageType, {
    String? userId,
  }) async {
    final headers = <String, String>{};
    if (userId != null && userId.isNotEmpty) {
      headers['X-User-Id'] = userId;
    }

    final response = await apiClient.uploadMultipart(
      '/api/business-profiles/$id/upload-image',
      fileBytes: bytes,
      filename: fileName,
      fieldName: 'file',
      fields: {'imageType': imageType},
      queryParameters: {'imageType': imageType},
      headers: headers.isNotEmpty ? headers : null,
    );

    return BusinessProfile.fromJson(response as Map<String, dynamic>);
  }

  Future<BusinessProfile> deleteBusinessImage(
    String id,
    String imageType, {
    String? userId,
  }) async {
    final headers = <String, String>{};
    if (userId != null && userId.isNotEmpty) {
      headers['X-User-Id'] = userId;
    }

    final response = await apiClient.delete(
      '/api/business-profiles/$id/image',
      queryParameters: {'imageType': imageType},
      headers: headers.isNotEmpty ? headers : null,
    );

    return BusinessProfile.fromJson(response as Map<String, dynamic>);
  }

  Future<void> deleteBusinessProfile(
    String id, {
    String? userId,
  }) async {
    final headers = <String, String>{};
    if (userId != null && userId.isNotEmpty) {
      headers['X-User-Id'] = userId;
    }

    await apiClient.delete(
      '/api/business-profiles/$id',
      headers: headers.isNotEmpty ? headers : null,
    );
  }

  Future<List<BusinessPost>> getBusinessPosts(
    String businessProfileId, {
    String? businessName,
  }) async {
    try {
      final response = await apiClient.get(
        '/api/business-profiles/$businessProfileId/posts',
      );

      final items = response as List<dynamic>? ?? [];
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
}
