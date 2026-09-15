import '../../../core/network/api_client.dart';
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
}
