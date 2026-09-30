import '../../../../core/config/app_config.dart';
import '../../../sustainable_products/domain/entities/product.dart';
import '../../../materials_marketplace/domain/entities/material_listing.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/entities/transaction_models.dart';

// Compatibility alias for existing transaction screens.
typedef Component4Config = AppConfig;

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

  Future<List<MaterialListing>> getMaterialListings({
    String? businessId,
    int status = 0,
  }) async {
    final listings = <MaterialListing>[];
    var page = 1;
    while (true) {
      final query = Uri(
        queryParameters: {
          'page': '$page',
          'pageSize': '100',
          'status': '$status',
          'businessId': ?businessId,
        },
      ).query;
      final body = await _get('/MaterialListings?$query');
      listings.addAll(
        (body['items'] as List).map(
          (item) => MaterialListing.fromJson(item as Map<String, dynamic>),
        ),
      );
      if (page >= (body['totalPages'] as int)) return listings;
      page++;
    }
  }

  Future<List<Product>> getProducts() async {
    final products = <Product>[];
    var page = 1;
    while (true) {
      final body = await _get('/products?page=$page&pageSize=100');
      products.addAll(
        (body['items'] as List).map(
          (item) => Product.fromJson(item as Map<String, dynamic>),
        ),
      );
      if (page >= (body['totalPages'] as int)) return products;
      page++;
    }
  }

  Future<MaterialListing> saveMaterialListing({
    String? id,
    required Map<String, dynamic> fields,
    List<int>? imageBytes,
    String? imageName,
  }) async {
    if (id != null) {
      return MaterialListing.fromJson(
        await _request('PUT', '/MaterialListings/$id', fields),
      );
    }
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/MaterialListings'),
    );
    request.fields.addAll({
      ...fields.map((key, value) => MapEntry(key, value.toString())),
      'businessId': AppConfig.currentBusinessId,
    });
    if (imageBytes != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: imageName ?? 'listing.jpg',
        ),
      );
    }
    return MaterialListing.fromJson(await _send(request));
  }

  Future<void> changeListingStatus(String id, int status) async {
    final request = http.Request(
      'PATCH',
      Uri.parse('$baseUrl/MaterialListings/$id/status'),
    );
    request.headers['Content-Type'] = 'application/json';
    request.body = jsonEncode(status);
    await _send(request);
  }

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

  /// Place name for a coordinate, e.g. "Galle Road, Kollupitiya, Colombo, ...".
  Future<String> reverseGeocode(double lat, double lng) async {
    final json = await _get(
      '/delivery-routes/reverse?lat=${lat.toStringAsFixed(6)}&lng=${lng.toStringAsFixed(6)}',
    );
    return json['name'] as String;
  }

  /// Coordinates for a place name, as `(lat, lng)`.
  Future<(double, double)> geocode(String query) async {
    final json = await _get(
      '/delivery-routes/geocode?q=${Uri.encodeQueryComponent(query)}',
    );
    return ((json['lat'] as num).toDouble(), (json['lng'] as num).toDouble());
  }

  Future<Map<String, dynamic>> _get(String path) => _request('GET', path);
  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) =>
      _request('POST', path, body);

  Future<Map<String, dynamic>> _request(
    String method,
    String path, [
    Map<String, dynamic>? body,
  ]) async {
    final request = http.Request(method, Uri.parse('$baseUrl$path'));
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }
    return _send(request);
  }

  Future<Map<String, dynamic>> _send(http.BaseRequest request) async {
    try {
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
