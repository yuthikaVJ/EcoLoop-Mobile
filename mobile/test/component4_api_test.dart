import 'dart:convert';
import 'package:eco_loop/features/transactions_delivery/data/services/component4_api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test(
    'posting a listing uploads shared business identity and delivery fields',
    () async {
      final api = Component4ApiService(
        client: MockClient((request) async {
          expect(request.method, 'POST');
          expect(request.url.path, '/api/MaterialListings');
          expect(
            request.headers['content-type'],
            startsWith('multipart/form-data'),
          );
          expect(request.body, contains(Component4Config.currentBusinessId));
          expect(request.body, contains('name="sellerDeliveryAvailable"'));
          expect(request.body, contains('filename="copper.jpg"'));
          return http.Response(
            jsonEncode({
              'id': 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
              'businessId': Component4Config.currentBusinessId,
              'title': 'Copper',
              'description': 'Wire',
              'category': 'Metals',
              'quantity': '5',
              'unit': 'Kgs',
              'price': 35,
              'priceUnit': 'Kgs',
              'location': 'Colombo',
              'seller': 'Seller',
              'type': 0,
              'createdAt': '2026-09-27T00:00:00Z',
              'sellerDeliveryAvailable': true,
            }),
            201,
          );
        }),
      );
      final listing = await api.saveMaterialListing(
        fields: {
          'title': 'Copper',
          'unit': 'Kgs',
          'sellerDeliveryAvailable': true,
        },
        imageBytes: [1, 2, 3],
        imageName: 'copper.jpg',
      );
      expect(listing.businessId, Component4Config.currentBusinessId);
      expect(listing.quantity, '5');
    },
  );

  test(
    'my listings filter and status changes use the backend contract',
    () async {
      final api = Component4ApiService(
        client: MockClient((request) async {
          if (request.method == 'GET') {
            expect(
              request.url.queryParameters['businessId'],
              Component4Config.currentBusinessId,
            );
            expect(request.url.queryParameters['status'], '1');
            return http.Response('{"items":[],"totalPages":0}', 200);
          }
          expect(request.method, 'PATCH');
          expect(request.url.path, '/api/MaterialListings/listing-id/status');
          expect(jsonDecode(request.body), 2);
          return http.Response('', 204);
        }),
      );
      await api.getMaterialListings(
        businessId: Component4Config.currentBusinessId,
        status: 1,
      );
      await api.changeListingStatus('listing-id', 2);
    },
  );

  test(
    'published listings preserve transaction identity and load every page',
    () async {
      var calls = 0;
      final api = Component4ApiService(
        client: MockClient((request) async {
          calls++;
          expect(request.url.path, '/api/MaterialListings');
          expect(request.url.queryParameters['page'], '$calls');
          return http.Response(
            jsonEncode({
              'totalPages': 2,
              'items': [
                {
                  'id': 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
                  'businessId': 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
                  'title': 'Copper',
                  'description': 'Clean wire',
                  'category': 'METALS',
                  'quantity': '500',
                  'unit': 'Kgs',
                  'location': 'Colombo',
                  'price': 35,
                  'priceUnit': 'Kg',
                  'seller': 'Copper seller',
                  'sellerIsVerified': true,
                  'type': 1,
                  'createdAt': '2026-09-27T10:00:00Z',
                  'sellerDeliveryAvailable': true,
                },
              ],
            }),
            200,
          );
        }),
      );
      final listings = await api.getMaterialListings();
      expect(listings, hasLength(2));
      expect(listings.first.businessId, 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb');
      expect(listings.first.unit, 'Kgs');
      expect(listings.first.isIHave, isFalse);
      expect(listings.first.sellerDeliveryAvailable, isTrue);
    },
  );

  test('history request includes selected page and seller role', () async {
    final api = Component4ApiService(
      client: MockClient((request) async {
        expect(request.url.path, contains('/product-orders/seller/'));
        expect(request.url.queryParameters['page'], '3');
        expect(request.url.queryParameters['pageSize'], '20');
        return http.Response('{"items":[]}', 200);
      }),
    );
    expect(await api.getProductOrders(seller: true, page: 3), isEmpty);
  });

  test('location edit preserves server concurrency token', () async {
    final api = Component4ApiService(
      client: MockClient((request) async {
        expect(request.method, 'PUT');
        final body = jsonDecode(request.body);
        expect(body['expectedUpdatedAt'], '2026-09-24T10:12:13.123456Z');
        expect(body['location'], 'Warehouse');
        expect(
          request.url.path,
          endsWith('/material-transactions/record/delivery'),
        );
        return http.Response('{}', 200);
      }),
    );
    await api.updateLocation(
      order: false,
      id: 'record',
      location: 'Warehouse',
      updatedAt: '2026-09-24T10:12:13.123456Z',
    );
  });

  test('non-JSON server failure produces a readable API exception', () async {
    final api = Component4ApiService(
      client: MockClient((_) async => http.Response('<html>Error</html>', 502)),
    );
    await expectLater(
      api.getLocations(),
      throwsA(
        isA<Component4ApiException>().having(
          (e) => e.message,
          'message',
          contains('502'),
        ),
      ),
    );
  });

  test('conflict message is shown rather than silently retried', () async {
    var calls = 0;
    final api = Component4ApiService(
      client: MockClient((_) async {
        calls++;
        return http.Response('{"message":"Reload this record."}', 409);
      }),
    );
    await expectLater(
      api.performAction(order: true, id: 'order', action: 'cancel'),
      throwsA(
        isA<Component4ApiException>().having(
          (e) => e.message,
          'message',
          'Reload this record.',
        ),
      ),
    );
    expect(calls, 1);
  });

  test('timeout reports a recoverable message', () async {
    final api = Component4ApiService(
      timeout: const Duration(milliseconds: 1),
      client: MockClient((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 30));
        return http.Response('{"items":[]}', 200);
      }),
    );
    await expectLater(
      api.getLocations(),
      throwsA(
        isA<Component4ApiException>().having(
          (e) => e.message,
          'message',
          contains('timed out'),
        ),
      ),
    );
  });
}
