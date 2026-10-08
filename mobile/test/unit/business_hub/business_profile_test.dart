import 'package:flutter_test/flutter_test.dart';
import 'package:eco_loop/features/business_hub/domain/entities/business_profile.dart';

void main() {
  group('BusinessProfile Entity Tests', () {
    test('fromJson parses API response properly including bio and coverPhotoUrl', () {
      final json = {
        'id': 'e5b7b752-628d-4e9a-9e12-32b0ebfa8211',
        'businessName': 'EcoRecycle Solutions',
        'businessType': 'Recycling Company',
        'registrationNumber': 'PV-98234',
        'bio': 'Pioneering circular waste management in Sri Lanka',
        'description': 'Industrial recycling of plastics and paper',
        'email': 'contact@ecorecycle.lk',
        'phone': '+94771234567',
        'address': '45 Industrial Estate, Ekala',
        'websiteUrl': 'https://ecorecycle.lk',
        'logoUrl': 'https://ecorecycle.lk/logo.png',
        'coverPhotoUrl': 'https://ecorecycle.lk/cover.jpg',
        'isVerified': true,
        'status': 'Verified',
        'userId': '11111111-1111-1111-1111-111111111111',
        'createdAt': '2026-09-15T12:00:00Z',
      };

      final profile = BusinessProfile.fromJson(json);

      expect(profile.id, 'e5b7b752-628d-4e9a-9e12-32b0ebfa8211');
      expect(profile.businessName, 'EcoRecycle Solutions');
      expect(profile.businessType, 'Recycling Company');
      expect(profile.registrationNumber, 'PV-98234');
      expect(profile.bio, 'Pioneering circular waste management in Sri Lanka');
      expect(profile.description, 'Industrial recycling of plastics and paper');
      expect(profile.email, 'contact@ecorecycle.lk');
      expect(profile.phone, '+94771234567');
      expect(profile.address, '45 Industrial Estate, Ekala');
      expect(profile.coverPhotoUrl, 'https://ecorecycle.lk/cover.jpg');
      expect(profile.isVerified, true);
      expect(profile.status, 'Verified');
      expect(profile.userId, '11111111-1111-1111-1111-111111111111');
      expect(profile.createdAt, isNotNull);
    });

    test('toJson serializes correctly including bio and coverPhotoUrl', () {
      const profile = BusinessProfile(
        id: '',
        businessName: 'Green Bio Products',
        businessType: 'Sustainable Product Business',
        registrationNumber: 'BR-44556',
        bio: 'Zero-waste bamboo goods',
        description: 'Sustainable personal care items',
        email: 'info@greenbio.lk',
        phone: '+94112345678',
        address: '10 Flower Road, Colombo',
        coverPhotoUrl: 'https://example.com/banner.jpg',
        userId: '22222222-2222-2222-2222-222222222222',
      );

      final json = profile.toJson();

      expect(json['businessName'], 'Green Bio Products');
      expect(json['businessType'], 'Sustainable Product Business');
      expect(json['registrationNumber'], 'BR-44556');
      expect(json['bio'], 'Zero-waste bamboo goods');
      expect(json['description'], 'Sustainable personal care items');
      expect(json['email'], 'info@greenbio.lk');
      expect(json['phone'], '+94112345678');
      expect(json['address'], '10 Flower Road, Colombo');
      expect(json['coverPhotoUrl'], 'https://example.com/banner.jpg');
      expect(json['userId'], '22222222-2222-2222-2222-222222222222');
    });

    test('copyWith updates specific fields while retaining others', () {
      const original = BusinessProfile(
        id: '123',
        businessName: 'Eco Original',
        businessType: 'Recycling Company',
        registrationNumber: 'REG-1',
        bio: 'Old bio',
        email: 'info@eco.lk',
        phone: '1234567',
        address: 'Old Address',
      );

      final updated = original.copyWith(
        businessName: 'Eco Renamed',
        bio: 'New bio',
        coverPhotoUrl: 'https://example.com/newcover.jpg',
      );

      expect(updated.id, '123');
      expect(updated.businessName, 'Eco Renamed');
      expect(updated.businessType, 'Recycling Company');
      expect(updated.bio, 'New bio');
      expect(updated.coverPhotoUrl, 'https://example.com/newcover.jpg');
      expect(updated.email, 'info@eco.lk');
    });
  });
}
