// API integration - material marketplace
// (lib/features/materials_marketplace/data/repositories/material_listing_repository.dart)
// The real repository, ApiClient and AuthRepository talk to a fake backend.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:eco_loop/core/config/app_config.dart';
import 'package:eco_loop/core/network/api_client.dart';
import 'package:eco_loop/features/auth/data/repositories/auth_repository.dart';
import 'package:eco_loop/features/materials_marketplace/data/repositories/material_listing_repository.dart';

import '../../helpers/fake_server.dart';

const path = '/api/MaterialListings';

Map<String, dynamic> listing(String id, {int type = 0}) => {
      'id': id,
      'title': 'PET bottles',
      'category': 'Plastics',
      'quantity': '500',
      'unit': 'Kgs',
      'location': 'Colombo',
      'price': 120,
      'priceUnit': 'Kg',
      'type': type,
      'status': 0,
      'seller': 'GreenCycle',
      'sellerIsVerified': true,
      'createdAt': '2026-10-01T10:00:00Z',
      'imageUrl': '/uploads/material_listings/$id.jpg',
      'imageUrls': ['/uploads/material_listings/$id.jpg'],
    };

void main() {
  late FakeServer server;
  late MaterialListingRepository repository;

  setUp(() {
    signIn();
    server = FakeServer();
    repository = MaterialListingRepository(ApiClient(AuthRepository()));
  });

  test('loads the marketplace with the user\'s token', () async {
    server.json('GET', path, {'items': [listing('l1'), listing('l2', type: 1)]});

    final listings = await server.run(() => repository.getListings(search: 'PET'));

    expect(listings.map((l) => l.id), ['l1', 'l2']);
    expect(listings.first.isIHave, isTrue);
    final request = server.last('GET', path);
    expect(request.headers['Authorization'], 'Bearer access-1');
    expect(request.url.queryParameters, containsPair('search', 'PET'));
    expect(listings.first.imageUrl, '${AppConfig.serverUrl}/uploads/material_listings/l1.jpg');
  });

  test('refreshes an expired session once and retries', () async {
    var calls = 0;
    server.on('GET', path, (r) => calls++ == 0
        ? http.Response('', 401)
        : http.Response(jsonEncode({'items': [listing('l1')]}), 200));
    server.json('POST', '/api/auth/refresh', {'token': 'access-2', 'refreshToken': 'refresh-2'});

    final listings = await server.run(() => repository.getListings());

    expect(listings, hasLength(1));
    expect(jsonDecode(server.last('POST', '/api/auth/refresh').body),
        {'accessToken': 'access-1', 'refreshToken': 'refresh-1'});
    expect(server.last('GET', path).headers['Authorization'], 'Bearer access-2');
  });

  test('server errors become a readable exception', () async {
    server.on('GET', path, (_) => http.Response('boom', 500));
    await expectLater(server.run(() => repository.getListings()), throwsA(isA<Exception>()));
  });

  test('posting a listing uploads every photo and the details as a form', () async {
    final dir = await Directory.systemTemp.createTemp('ecoloop');
    final photos = [for (final n in ['a', 'b']) await File('${dir.path}/$n.jpg').writeAsBytes([1, 2, 3])];
    server.json('POST', path, listing('new'), status: 201);

    final created = await server.run(() => repository.createListing(
          {'title': 'PET bottles', 'type': 0, 'postedAsBusinessId': 'biz-1', 'availability': 'Immediately'},
          imageFiles: photos,
        ));

    expect(created.id, 'new');
    final body = server.last('POST', path).body;
    expect(RegExp('name="images"').allMatches(body), hasLength(2));
    expect(body, contains('name="postedAsBusinessId"'));
    expect(body, contains('name="availability"'));
    await dir.delete(recursive: true);
  });

  test('editing sends the kept photos, then uploads new ones', () async {
    final dir = await Directory.systemTemp.createTemp('ecoloop');
    final photo = await File('${dir.path}/c.jpg').writeAsBytes([1]);
    server.json('PUT', '$path/l1', listing('l1'));
    server.json('POST', '$path/l1/images', listing('l1'));

    await server.run(() async {
      await repository.updateListing('l1', {'title': 'PET', 'keepImageUrls': ['/uploads/a.jpg']});
      await repository.addImages('l1', [photo]);
    });

    expect(jsonDecode(server.last('PUT', '$path/l1').body)['keepImageUrls'], ['/uploads/a.jpg']);
    expect(server.last('POST', '$path/l1/images').body, contains('name="images"'));
    await dir.delete(recursive: true);
  });

  test('mark as sold sends the new status', () async {
    server.on('PATCH', '$path/l1/status', (_) => http.Response('', 204));

    final ok = await server.run(() => repository.changeStatus('l1', 1));

    expect(ok, isTrue);
    expect(server.last('PATCH', '$path/l1/status').body, '1');
  });
}
