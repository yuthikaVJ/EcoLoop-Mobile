import 'dart:convert';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/business_profile.dart';

class ProfileRepository {
  final ApiClient _apiClient;
  final String _baseUrl = 'http://10.0.2.2:5252/api/business';

  ProfileRepository(this._apiClient);

  Future<BusinessProfile> getProfile() async {
    final response = await _apiClient.get('$_baseUrl/me');

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return BusinessProfile.fromJson(data);
    } else {
      throw Exception('Failed to load profile');
    }
  }

  Future<BusinessProfile> updateProfile(BusinessProfile profile) async {
    final response = await _apiClient.put(
      '$_baseUrl/me',
      body: json.encode(profile.toJson()),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return BusinessProfile.fromJson(data);
    } else {
      throw Exception('Failed to update profile');
    }
  }
}
