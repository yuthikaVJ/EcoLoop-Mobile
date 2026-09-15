import 'package:flutter_test/flutter_test.dart';
import 'package:eco_loop/features/business_hub/domain/entities/business_profile.dart';

void main() {
  group('BusinessProfile Entity Tests', () {
    test('fromJson parses API response properly', () {
      final json = {
        'id': 'e5b7b752-628d-4e9a-9e12-32b0ebfa8211',
        'businessName': 'EcoRecycle Solutions',
        'businessType': 'Recycling Company',
        'registrationNumber': 'PV-98234',
        'description': 'Industrial recycling of plastics and paper',
        'email': 'contact@ecorecycle.lk',
        'phone': '+94771234567',
        'address': '45 Industrial Estate, Ekala',
        'websiteUrl': 'https://ecorecycle.lk',
        'logoUrl': 'https://ecorecycle.lk/logo.png',
        'isVerified': false,
        'status': 'Unverified',
        'userId': '11111111-1111-1111-1111-111111111111',
        'createdAt': '2026-09-15T12:00:00Z',
      };

      final profile = BusinessProfile.fromJson(json);

      expect(profile.id, 'e5b7b752-628d-4e9a-9e12-32b0ebfa8211');
      expect(profile.businessName, 'EcoRecycle Solutions');
      expect(profile.businessType, 'Recycling Company');
      expect(profile.registrationNumber, 'PV-98234');
      expect(profile.description, 'Industrial recycling of plastics and paper');
      expect(profile.email, 'contact@ecorecycle.lk');
      expect(profile.phone, '+94771234567');
      expect(profile.address, '45 Industrial Estate, Ekala');
      expect(profile.isVerified, false);
      expect(profile.status, 'Unverified');
      expect(profile.userId, '11111111-1111-1111-1111-111111111111');
      expect(profile.createdAt, isNotNull);
    });

    test('toJson serializes correctly for creation request', () {
      const profile = BusinessProfile(
        id: '',
        businessName: 'Green Bio Products',
        businessType: 'Sustainable Product Business',
        registrationNumber: 'BR-44556',
        email: 'info@greenbio.lk',
        phone: '+94112345678',
        address: '10 Flower Road, Colombo',
        userId: '22222222-2222-2222-2222-222222222222',
      );

      final json = profile.toJson();

      expect(json['businessName'], 'Green Bio Products');
      expect(json['businessType'], 'Sustainable Product Business');
      expect(json['registrationNumber'], 'BR-44556');
      expect(json['email'], 'info@greenbio.lk');
      expect(json['phone'], '+94112345678');
      expect(json['address'], '10 Flower Road, Colombo');
      expect(json['userId'], '22222222-2222-2222-2222-222222222222');
    });
  });
}
