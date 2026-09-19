import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/entities/transaction_models.dart';

class Component4Config {
  static const apiBaseUrl = String.fromEnvironment(
    'ECOLOOP_API_URL',
    defaultValue: 'http://10.0.2.2:5252/api',
  );

  // Temporary Business identity until the group authentication component supplies JWT claims.
  static const currentBusinessId = String.fromEnvironment(
    'ECOLOOP_BUSINESS_ID',
    defaultValue: '22222222-2222-2222-2222-222222222222',
  );
}

class Component4ApiException implements Exception {
  final String message;
  const Component4ApiException(this.message);
  @override
  String toString() => message;
}

class Component4ApiService {
  final http.Client _client;
  final String baseUrl;

  Component4ApiService({http.Client? client, this.baseUrl = Component4Config.apiBaseUrl})
      : _client = client ?? http.Client();

  Future<List<MaterialTransactionSummary>> getMaterialTransactions({required bool seller}) async {
    final path = seller ? 'seller' : 'buyer';
    final json = await _get('/material-transactions/$path/${Component4Config.currentBusinessId}');
    return (json['items'] as List? ?? []).map((x) => MaterialTransactionSummary.fromJson(x)).toList();
  }

  Future<List<ProductOrderSummary>> getProductOrders({required bool seller}) async {
    final path = seller ? 'seller' : 'buyer';
    final json = await _get('/product-orders/$path/${Component4Config.currentBusinessId}');
    return (json['items'] as List? ?? []).map((x) => ProductOrderSummary.fromJson(x)).toList();
  }

  Future<MaterialTransactionDetails> getMaterialTransaction(String id) async =>
      MaterialTransactionDetails.fromJson(await _get('/material-transactions/$id'));

  Future<ProductOrderDetails> getProductOrder(String id) async =>
      ProductOrderDetails.fromJson(await _get('/product-orders/$id'));

  Future<MaterialTransactionDetails> createMaterialTransaction({
    required String listingId,
    required String sellerBusinessId,
    required double quantity,
    required String unit,
    required double unitPrice,
    required DeliveryMethod method,
    String? location,
  }) async => MaterialTransactionDetails.fromJson(await _post('/material-transactions', {
        'materialListingId': listingId,
        'buyerBusinessId': Component4Config.currentBusinessId,
        'sellerBusinessId': sellerBusinessId,
        'quantity': quantity,
        'unit': unit,
        'unitPrice': unitPrice,
        'delivery': {'method': method.index, 'location': location},
      }));

  Future<ProductOrderDetails> createProductOrder({
    required List<Map<String, dynamic>> items,
    required DeliveryMethod method,
    String? location,
  }) async => ProductOrderDetails.fromJson(await _post('/product-orders', {
        'buyerBusinessId': Component4Config.currentBusinessId,
        'items': items,
        'delivery': {'method': method.index, 'location': location},
      }));

  Future<void> performAction({required bool order, required String id, required String action, String? note}) async {
    await _post('/${order ? 'product-orders' : 'material-transactions'}/$id/$action', {
      'actingBusinessId': Component4Config.currentBusinessId,
      'note': note,
    });
  }

  Future<Map<String, dynamic>> _get(String path) async {
    final response = await _client.get(Uri.parse('$baseUrl$path'));
    return _decode(response);
  }

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) async {
    final response = await _client.post(
      Uri.parse('$baseUrl$path'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    return _decode(response);
  }

  Map<String, dynamic> _decode(http.Response response) {
    final dynamic body = response.body.isEmpty ? <String, dynamic>{} : jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = body is Map<String, dynamic> ? body['message']?.toString() : null;
      throw Component4ApiException(message ?? 'Request failed (${response.statusCode}).');
    }
    return body is Map<String, dynamic> ? body : <String, dynamic>{};
  }
}
