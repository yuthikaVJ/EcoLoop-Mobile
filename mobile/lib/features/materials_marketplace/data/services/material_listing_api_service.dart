import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../transactions_delivery/data/services/component4_api_service.dart';
import '../../domain/entities/material_listing.dart';

class MaterialListingApiService {
  final String baseUrl;
  final Duration timeout;

  MaterialListingApiService({
    this.baseUrl = Component4Config.apiBaseUrl,
    this.timeout = const Duration(seconds: 20),
  });

  String get _listingsUrl => '$baseUrl/MaterialListings';

  /// Active listings shown in the marketplace. [isIHave] filters by tab.
  Future<List<MaterialListing>> getListings({bool? isIHave}) async {
    final uri = Uri.parse(_listingsUrl).replace(queryParameters: {
      if (isIHave != null) 'type': isIHave ? '0' : '1',
      'page': '1',
      'pageSize': '100',
    });
    final body = await _send(() => http.get(uri));
    return _parseItems(body);
  }

  /// Active and completed listings posted by the current business.
  Future<List<MaterialListing>> getMyListings() async {
    final uri = Uri.parse(
      '$_listingsUrl/business/${Component4Config.currentBusinessId}',
    );
    final body = await _send(() => http.get(uri));
    return _parseItems(body);
  }

  Future<MaterialListing> createListing({
    required String title,
    required String category,
    required String description,
    required String quantity,
    required String unit,
    required String location,
    required double price,
    required String priceUnit,
    required String deliveryMethod,
    required bool isIHave,
    String? imagePath,
  }) async {
    final request = http.MultipartRequest('POST', Uri.parse(_listingsUrl))
      ..fields.addAll({
        'businessId': Component4Config.currentBusinessId,
        'title': title,
        'category': category,
        'description': description,
        'quantity': quantity,
        'unit': unit,
        'location': location,
        'price': price.toString(),
        'priceUnit': priceUnit,
        'deliveryMethod': deliveryMethod,
        'sellerDeliveryAvailable':
            (deliveryMethod == 'Seller Delivery').toString(),
        'type': isIHave ? '0' : '1',
      });
    if (imagePath != null) {
      request.files.add(await http.MultipartFile.fromPath('image', imagePath));
    }
    final body = await _send(
      () async => http.Response.fromStream(await request.send()),
    );
    return MaterialListing.fromJson(body as Map<String, dynamic>);
  }

  /// 1 = Completed (mark as sold), 2 = Deleted.
  Future<void> changeStatus(String id, int status) async {
    await _send(
      () => http.patch(
        Uri.parse('$_listingsUrl/$id/status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(status),
      ),
    );
  }

  List<MaterialListing> _parseItems(dynamic body) {
    final items = body is Map ? body['items'] as List? ?? [] : [];
    return items
        .map((x) => MaterialListing.fromJson(x as Map<String, dynamic>))
        .toList();
  }

  Future<dynamic> _send(Future<http.Response> Function() call) async {
    final http.Response response;
    try {
      response = await call().timeout(timeout);
    } on TimeoutException {
      throw const Component4ApiException(
        'Request timed out. Check your connection and try again.',
      );
    } on http.ClientException {
      throw const Component4ApiException(
        'Cannot connect to EcoLoop. Check your connection and try again.',
      );
    }

    dynamic body;
    try {
      body = response.body.isEmpty ? null : jsonDecode(response.body);
    } on FormatException {
      body = null;
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = body is Map
          ? (body['message'] ?? body['title'])?.toString()
          : null;
      throw Component4ApiException(
        message ?? 'Request failed (${response.statusCode}).',
      );
    }
    return body;
  }
}
