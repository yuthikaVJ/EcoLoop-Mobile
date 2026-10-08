// Sustainable products - product model
// (lib/features/sustainable_products/domain/entities/product.dart).
import 'package:flutter_test/flutter_test.dart';

import 'package:eco_loop/features/sustainable_products/domain/entities/product.dart';

void main() {
  final json = {
    'id': 'p1',
    'businessId': 'b1',
    'name': 'Reusable bottle',
    'description': 'Steel',
    'materialType': 'Metal',
    'price': 25,
    'category': 'Home & Garden',
    'seller': 'GreenCycle',
    'sellerIsVerified': true,
    'sellerLogoUrl': '/uploads/logo.png',
    'availableQuantity': 10,
    'sellerDeliveryAvailable': true,
    'images': ['data:image/png;base64,AAA', 'data:image/png;base64,BBB'],
  };

  test('reads a product from the API', () {
    final product = Product.fromJson(json);

    expect(product.name, 'Reusable bottle');
    expect(product.price, 25.0);
    expect(product.seller, 'GreenCycle');
    expect(product.sellerIsVerified, isTrue);
    expect(product.availableQuantity, 10);
    expect(product.images, hasLength(2));
  });

  test('the first photo is used when no primary photo is marked', () {
    expect(Product.fromJson(json).primaryImageUrl, 'data:image/png;base64,AAA');
    expect(Product.fromJson({...json, 'primaryImageUrl': 'data:x'}).primaryImageUrl, 'data:x');
    expect(Product.fromJson({...json, 'images': <String>[]}).primaryImageUrl, isNull);
  });

  test('missing fields fall back to safe defaults', () {
    final product = Product.fromJson({'id': 'p2'});

    expect(product.name, isEmpty);
    expect(product.price, 0);
    expect(product.sellerIsVerified, isFalse);
    expect(product.availableQuantity, 0);
    expect(product.images, isEmpty);
  });

  test('copyWith changes only the given fields and keeps the seller', () {
    final product = Product.fromJson(json).copyWith(price: 30, availableQuantity: 4);

    expect(product.price, 30);
    expect(product.availableQuantity, 4);
    expect(product.name, 'Reusable bottle');
    expect(product.sellerLogoUrl, '/uploads/logo.png');
  });
}
