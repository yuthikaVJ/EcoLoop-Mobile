// API integration - Business Hub (lib/features/business_hub/data/business_repository.dart).
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:eco_loop/core/network/api_client.dart';
import 'package:eco_loop/features/auth/data/repositories/auth_repository.dart';
import 'package:eco_loop/features/business_hub/data/business_repository.dart';

import '../../helpers/fake_server.dart';

const path = '/api/business-profiles';

Map<String, dynamic> profile(String id, {String status = 'Unverified'}) => {
      'id': id, 'businessName': 'GreenCycle', 'businessType': 'Recycling Company', 'registrationNumber': 'PV-1',
      'email': 'green@ecoloop.lk', 'phone': '0771234567', 'address': 'Colombo', 'isVerified': status == 'Verified',
      'status': status, 'userId': 'acc-1',
    };

void main() {
  late FakeServer server;
  late BusinessRepository repository;

  setUp(() {
    signIn();
    server = FakeServer();
    repository = BusinessRepository(apiClient: ApiClient(AuthRepository()));
  });

  test('creating a business sends the form as JSON with the user\'s token', () async {
    server.json('POST', path, profile('b1'), status: 201);

    final created = await server.run(() => repository.createBusinessProfile({'businessName': 'GreenCycle'}));

    expect(created.status, 'Unverified');
    final request = server.last('POST', path);
    expect(jsonDecode(request.body), {'businessName': 'GreenCycle'});
    expect(request.headers['Authorization'], 'Bearer access-1');
  });

  test('lists only my businesses', () async {
    server.json('GET', '$path/my', [profile('b1', status: 'Verified'), profile('b2')]);

    final mine = await server.run(repository.getMyBusinessProfiles);

    expect(mine.map((b) => b.isVerified), [true, false]);
  });

  test('uploading a logo sends a multipart file with the image type', () async {
    server.json('POST', '$path/b1/upload-image', profile('b1'));

    await server.run(() => repository.uploadBusinessImage('b1', [1, 2, 3], 'logo.png', 'profile'));

    final request = server.last('POST', '$path/b1/upload-image');
    expect(request.url.queryParameters['imageType'], 'profile');
    expect(request.body, contains('name="file"; filename="logo.png"'));
  });

  test('a missing profile is null, not an error', () async {
    server.json('GET', '$path/b9', {'message': 'Business profile not found.'}, status: 404);
    expect(await server.run(() => repository.getBusinessProfile('b9')), isNull);
  });

  test('validation errors from ASP.NET are shown as readable text', () async {
    server.json('POST', path, {
      'errors': {'Phone': ['Phone number must be exactly 10 digits.']},
    }, status: 400);

    final error = await server.run(() => repository.createBusinessProfile({})).then<Object?>((_) => null, onError: (e) => e);

    expect(error, isA<ApiException>().having((e) => e.message, 'message', 'Phone number must be exactly 10 digits.'));
  });
}
