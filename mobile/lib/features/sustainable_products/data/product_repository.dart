import '../../../core/network/api_client.dart';
import '../domain/entities/product.dart';

class ProductRepository {
  final ApiClient apiClient;

  ProductRepository({ApiClient? apiClient})
      : apiClient = apiClient ?? ApiClient();

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

    final items = response['items'] as List<dynamic>? ?? [];

    return items
        .map((item) => Product.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Product> getProduct(String id) async {
    final response = await apiClient.get('/api/products/$id');

    return Product.fromJson(response as Map<String, dynamic>);
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    final response = await apiClient.get('/api/product-categories');

    return (response as List<dynamic>)
        .map((item) => item as Map<String, dynamic>)
        .toList();
  }
}