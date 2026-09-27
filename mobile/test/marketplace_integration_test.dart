import 'dart:convert';
import 'package:eco_loop/core/config/app_config.dart';
import 'package:eco_loop/features/sustainable_products/presentation/pages/products_page.dart';
import 'package:eco_loop/features/transactions_delivery/data/services/component4_api_service.dart';
import 'package:eco_loop/features/transactions_delivery/presentation/pages/product_checkout_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

Map<String, dynamic> product({int stock = 3, String seller = 'seller-id'}) => {
  'id': 'product-id',
  'businessId': seller,
  'name': 'Reusable Bottle',
  'description': 'Steel bottle',
  'seller': 'Bottle Company',
  'price': 25,
  'availableQuantity': stock,
  'sellerDeliveryAvailable': true,
};

Component4ApiService catalogApi(Map<String, dynamic> item) =>
    Component4ApiService(
      client: MockClient((request) async {
        expect(request.url.path, '/api/products');
        return http.Response(
          jsonEncode({
            'items': [item],
            'totalPages': 1,
          }),
          200,
        );
      }),
    );

void main() {
  testWidgets(
    'live product selection carries quantity and delivery into checkout',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: ProductsPage(api: catalogApi(product()))),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Increase quantity'));
      await tester.tap(find.text('Buy Now'));
      await tester.pumpAndSettle();
      final checkout = tester.widget<ProductCheckoutPage>(
        find.byType(ProductCheckoutPage),
      );
      expect(checkout.items.single.productId, 'product-id');
      expect(checkout.items.single.quantity, 2);
      expect(checkout.items.single.unitPrice, 25);
      expect(checkout.items.single.sellerDeliveryAvailable, isTrue);
      expect(find.text('Confirm Order'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('out of stock and own products cannot be purchased', (
    tester,
  ) async {
    for (final item in [
      product(stock: 0),
      product(seller: AppConfig.currentBusinessId),
    ]) {
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        MaterialApp(home: ProductsPage(api: catalogApi(item))),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
        isNull,
      );
    }
  });

  test('catalog failure can be retried', () async {
    var attempts = 0;
    final api = Component4ApiService(
      client: MockClient((_) async {
        if (++attempts == 1) {
          return http.Response('{"message":"Try again"}', 503);
        }
        return http.Response('{"items":[],"totalPages":0}', 200);
      }),
    );
    await expectLater(
      api.getProducts(),
      throwsA(isA<Component4ApiException>()),
    );
    expect(await api.getProducts(), isEmpty);
  });
}
