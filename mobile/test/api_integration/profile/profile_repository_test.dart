// API integration - My Profile (lib/features/profile/data/repositories/profile_repository.dart).
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:eco_loop/core/network/api_client.dart';
import 'package:eco_loop/features/auth/data/repositories/auth_repository.dart';
import 'package:eco_loop/features/profile/data/repositories/profile_repository.dart';
import 'package:eco_loop/features/profile/domain/entities/account_profile.dart';

import '../../helpers/fake_server.dart';

const me = {
  'id': 'acc-1', 'businessName': 'Haritha', 'email': 'haritha@example.com', 'phoneNumber': '0771234567',
  'address': 'Colombo', 'createdAt': '2026-09-12T08:00:00Z', 'isVerified': false,
};

void main() {
  late FakeServer server;
  late ProfileRepository repository;

  setUp(() {
    signIn();
    server = FakeServer();
    repository = ProfileRepository(ApiClient(AuthRepository()));
  });

  test('loads the signed-in account', () async {
    server.json('GET', '/api/business/me', me);

    final profile = await server.run(repository.getProfile);

    expect(profile.businessName, 'Haritha');
    expect(server.last('GET', '/api/business/me').headers['Authorization'], 'Bearer access-1');
  });

  test('saving sends only personal details', () async {
    server.json('PUT', '/api/business/me', {...me, 'phoneNumber': '0712345678'});

    final saved = await server.run(() => repository.updateProfile(AccountProfile.fromJson({...me, 'phoneNumber': '0712345678'})));

    expect(saved.phoneNumber, '0712345678');
    expect(jsonDecode(server.last('PUT', '/api/business/me').body),
        {'businessName': 'Haritha', 'phoneNumber': '0712345678', 'address': 'Colombo'});
  });

  test('a failed load is reported', () async {
    server.json('GET', '/api/business/me', {'message': 'Business profile not found.'}, status: 404);
    await expectLater(server.run(repository.getProfile), throwsA(isA<Exception>()));
  });
}
