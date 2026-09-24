import 'dart:async';
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
  final Duration timeout;
  final bool _ownsClient;
  void dispose() {
    if (_ownsClient) _client.close();
  }

  Component4ApiService({
    http.Client? client,
    this.baseUrl = Component4Config.apiBaseUrl,
    this.timeout = const Duration(seconds: 20),
  }) : _client = client ?? http.Client(),
       _ownsClient = client == null;

  Future<List<MaterialTransactionSummary>> getMaterialTransactions({
    required bool seller,
    int page = 1,
  }) async {
    final path = seller ? 'seller' : 'buyer';
    final json = await _get(
      '/material-transactions/$path/${Component4Config.currentBusinessId}?page=$page&pageSize=20',
    );
    return (json['items'] as List? ?? [])
        .map((x) => MaterialTransactionSummary.fromJson(x))
        .toList();
  }

  Future<List<ProductOrderSummary>> getProductOrders({
    required bool seller,
    int page = 1,
  }) async {
    final path = seller ? 'seller' : 'buyer';
    final json = await _get(
      '/product-orders/$path/${Component4Config.currentBusinessId}?page=$page&pageSize=20',
    );
    return (json['items'] as List? ?? [])
        .map((x) => ProductOrderSummary.fromJson(x))
        .toList();
  }

  Future<MaterialTransactionDetails> getMaterialTransaction(String id) async =>
      MaterialTransactionDetails.fromJson(
        await _get('/material-transactions/$id'),
      );

  Future<ProductOrderDetails> getProductOrder(String id) async =>
      ProductOrderDetails.fromJson(await _get('/product-orders/$id'));

  Future<MaterialTransactionDetails> createMaterialTransaction({
    required String listingId,
    required String sellerBusinessId,
    String buyerBusinessId = Component4Config.currentBusinessId,
    required double quantity,
    required String unit,
    required double unitPrice,
    required DeliveryMethod method,
    String? location,
  }) async => MaterialTransactionDetails.fromJson(
    await _post('/material-transactions', {
      'materialListingId': listingId,
      'buyerBusinessId': buyerBusinessId,
      'sellerBusinessId': sellerBusinessId,
      'quantity': quantity,
      'unit': unit,
      'unitPrice': unitPrice,
      'delivery': {'method': method.index, 'location': location},
    }),
  );

  Future<ProductOrderDetails> createProductOrder({
    required List<Map<String, dynamic>> items,
    required DeliveryMethod method,
    String? location,
  }) async => ProductOrderDetails.fromJson(
    await _post('/product-orders', {
      'buyerBusinessId': Component4Config.currentBusinessId,
      'items': items,
      'delivery': {'method': method.index, 'location': location},
    }),
  );

  Future<void> performAction({
    required bool order,
    required String id,
    required String action,
    String? note,
  }) async {
    await _post(
      '/${order ? 'product-orders' : 'material-transactions'}/$id/$action',
      {'actingBusinessId': Component4Config.currentBusinessId, 'note': note},
    );
  }

  Future<List<SavedLocation>> getLocations() async {
    final body = await _get(
      '/delivery-locations?businessId=${Component4Config.currentBusinessId}',
    );
    return (body['items'] as List)
        .map((x) => SavedLocation.fromJson(x))
        .toList();
  }

  Future<void> saveLocation({
    SavedLocation? existing,
    required String label,
    required String address,
  }) async {
    await _request(
      existing == null ? 'POST' : 'PUT',
      '/delivery-locations${existing == null ? '' : '/${existing.id}'}',
      {
        'businessId': Component4Config.currentBusinessId,
        'label': label,
        'address': address,
        ..._coordinateFields(address),
        'expectedUpdatedAt': existing?.updatedAt,
      },
    );
  }

  Map<String, double> _coordinateFields(String value) {
    final parts = value.split(',');
    if (parts.length != 2) return {};
    final lat = double.tryParse(parts[0].trim()),
        lng = double.tryParse(parts[1].trim());
    if (lat == null ||
        lng == null ||
        !lat.isFinite ||
        !lng.isFinite ||
        lat.abs() > 90 ||
        lng.abs() > 180) {
      return {};
    }
    return {'latitude': lat, 'longitude': lng};
  }

  Future<void> deleteLocation(String id) async => _request(
    'DELETE',
    '/delivery-locations/$id?businessId=${Component4Config.currentBusinessId}',
  );

  Future<void> updateLocation({
    required bool order,
    required String id,
    required String location,
    String? updatedAt,
  }) async {
    await _request(
      'PUT',
      '/${order ? 'product-orders' : 'material-transactions'}/$id/delivery',
      {
        'actingBusinessId': Component4Config.currentBusinessId,
        'location': location,
        'expectedUpdatedAt': updatedAt,
      },
    );
  }

  Future<void> updateMaterial(
    MaterialTransactionDetails item,
    double quantity,
    String unit,
    double price,
  ) async {
    await _request('PUT', '/material-transactions/${item.id}', {
      'actingBusinessId': Component4Config.currentBusinessId,
      'quantity': quantity,
      'unit': unit,
      'unitPrice': price,
      'expectedUpdatedAt': item.updatedAt,
    });
  }

  Future<Map<String, dynamic>> getRoute(String origin, String destination) =>
      _post('/delivery-routes', {'origin': origin, 'destination': destination});

  Future<Map<String, dynamic>> _get(String path) => _request('GET', path);
  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) =>
      _request('POST', path, body);

  Future<Map<String, dynamic>> _request(
    String method,
    String path, [
    Map<String, dynamic>? body,
  ]) async {
    try {
      final request = http.Request(method, Uri.parse('$baseUrl$path'));
      if (body != null) {
        request.headers['Content-Type'] = 'application/json';
        request.body = jsonEncode(body);
      }
      final response = await (() async => http.Response.fromStream(
        await _client.send(request),
      ))().timeout(timeout);
      return _decode(response);
    } on TimeoutException {
      throw const Component4ApiException(
        'Request timed out. Check your connection and try again.',
      );
    } on http.ClientException {
      throw const Component4ApiException(
        'Cannot connect to EcoLoop. Check your connection and try again.',
      );
    }
  }

  Map<String, dynamic> _decode(http.Response response) {
    dynamic body;
    try {
      body = response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body);
    } on FormatException {
      throw Component4ApiException(
        'The server returned an unreadable response (${response.statusCode}).',
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = body is Map
          ? (body['message'] ?? body['title'])?.toString()
          : null;
      throw Component4ApiException(
        message ?? 'Request failed (${response.statusCode}).',
      );
    }
    if (body is! Map<String, dynamic>) {
      throw const Component4ApiException('Unexpected server response.');
    }
    return body;
  }
}

class SavedLocation {
  final String id, label, address, updatedAt;
  const SavedLocation({
    required this.id,
    required this.label,
    required this.address,
    required this.updatedAt,
  });
  factory SavedLocation.fromJson(Map<String, dynamic> json) => SavedLocation(
    id: json['id'],
    label: json['label'],
    address: json['address'],
    updatedAt: json['updatedAt'],
  );
}
