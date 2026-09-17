import 'dart:convert';
import '../../../core/network/api_client.dart';
import '../domain/entities/product.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client_provider.dart';

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository(ref.read(apiClientProvider));
});

class ProductRepository {
  final ApiClient apiClient;

  ProductRepository(this.apiClient);

  Future<List<Product>> getProducts({
    String? search,
    String sort = 'newest',
  }) async {
    final response = await apiClient.get(
      '/api/products',
      queryParameters: {
        if (search != null && search.trim().isNotEmpty)
          'search': search.trim(),
        'sort': sort,
        'page': '1',
        'pageSize': '50',
      },
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);
      final items = data['items'] as List<dynamic>? ?? [];
      return items
          .map((item) => Product.fromJson(item as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Failed to load products');
    }
  }

  Future<Product> getProduct(String id) async {
    final response = await apiClient.get('/api/products/$id');
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return Product.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      throw Exception('Failed to load product');
    }
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    final response = await apiClient.get('/api/product-categories');
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return (jsonDecode(response.body) as List<dynamic>)
          .map((item) => item as Map<String, dynamic>)
          .toList();
    } else {
      throw Exception('Failed to load categories');
    }
  }

  Future<void> purchaseProduct(String id, int quantity) async {
    final response = await apiClient.post(
      '/api/products/$id/purchase',
      body: jsonEncode({'quantity': quantity}),
    );
    
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to process purchase');
    }
  }
}