// My Profile - personal account model
// (lib/features/profile/domain/entities/account_profile.dart). Business details
// live in Business Hub profiles, so only personal fields are sent on save.
import 'package:flutter_test/flutter_test.dart';

import 'package:eco_loop/features/profile/domain/entities/account_profile.dart';

void main() {
  final json = {
    'id': 'acc-1',
    'businessName': 'Haritha Geemal',
    'email': 'haritha@example.com',
    'logoUrl': 'https://lh3.googleusercontent.com/photo.jpg',
    'phoneNumber': '0771234567',
    'address': 'Colombo',
    'createdAt': '2026-09-12T08:00:00Z',
    'isVerified': false,
  };

  test('reads the personal profile from the API', () {
    final profile = AccountProfile.fromJson(json);

    expect(profile.businessName, 'Haritha Geemal');
    expect(profile.email, 'haritha@example.com');
    expect(profile.phoneNumber, '0771234567');
    expect(profile.address, 'Colombo');
    expect(profile.createdAt, DateTime.utc(2026, 9, 12, 8));
  });

  test('saving sends only name, mobile number and address', () {
    final body = AccountProfile.fromJson(json).toJson();

    expect(body, {'businessName': 'Haritha Geemal', 'phoneNumber': '0771234567', 'address': 'Colombo'});
  });

  test('optional contact details may be missing', () {
    final profile = AccountProfile.fromJson({...json, 'phoneNumber': null, 'address': null, 'email': null});

    expect(profile.phoneNumber, isNull);
    expect(profile.address, isNull);
    expect(profile.email, isNull);
  });
}
