import 'dart:convert';
import 'package:eco_loop/features/transactions_delivery/data/services/component4_api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
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
