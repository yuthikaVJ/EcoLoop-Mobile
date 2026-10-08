// Material marketplace - listing model
// (lib/features/materials_marketplace/domain/entities/material_listing.dart).
import 'package:flutter_test/flutter_test.dart';

import 'package:eco_loop/core/config/app_config.dart';
import 'package:eco_loop/features/materials_marketplace/domain/entities/material_listing.dart';

Map<String, dynamic> listingJson([Map<String, dynamic> overrides = const {}]) => {
      'id': 'l1',
      'businessId': 'b1',
      'title': 'PET bottles',
      'category': 'Plastics',
      'description': 'Clean and baled',
      'quantity': '500',
      'unit': 'Kgs',
      'location': 'Colombo',
      'price': 120,
      'priceUnit': 'Kg',
      'deliveryMethod': 'Seller Delivery',
      'sellerDeliveryAvailable': true,
      'seller': 'GreenCycle',
      'sellerIsVerified': true,
      'sellerLogoUrl': '/uploads/logo.png',
      'availability': 'Immediately',
      'condition': 'Clean',
      'type': 0,
      'status': 0,
      'createdAt': '2026-10-01T10:00:00Z',
      'imageUrl': '/uploads/material_listings/a.jpg',
      'imageUrls': ['/uploads/material_listings/a.jpg', '/uploads/material_listings/b.jpg'],
      ...overrides,
    };

void main() {
  const server = AppConfig.serverUrl;

  test('reads every field from the API', () {
    final listing = MaterialListing.fromJson(listingJson());

    expect(listing.title, 'PET bottles');
    expect(listing.isIHave, isTrue);
    expect(listing.price, 120.0);
    expect(listing.companyName, 'GreenCycle');
    expect(listing.isVerifiedSeller, isTrue);
    expect(listing.availability, 'Immediately');
    expect(listing.condition, 'Clean');
    expect(listing.sellerDeliveryAvailable, isTrue);
    expect(listing.datePosted, DateTime.utc(2026, 10, 1, 10));
  });

  test('type 1 is an I NEED post', () {
    expect(MaterialListing.fromJson(listingJson({'type': 1})).isIHave, isFalse);
  });

  test('photo paths become full URLs on this app\'s server', () {
    final listing = MaterialListing.fromJson(listingJson());

    expect(listing.imageUrl, '$server/uploads/material_listings/a.jpg');
    expect(listing.photos, ['$server/uploads/material_listings/a.jpg', '$server/uploads/material_listings/b.jpg']);
  });

  test('old emulator-only photo links are rewritten so they load on a real phone', () {
    final listing = MaterialListing.fromJson(listingJson({
      'imageUrl': 'http://10.0.2.2:5252/uploads/material_listings/a.jpg',
      'imageUrls': ['http://10.0.2.2:5252/uploads/material_listings/a.jpg'],
    }));

    expect(listing.imageUrl, '$server/uploads/material_listings/a.jpg');
    expect(listing.photos.single, '$server/uploads/material_listings/a.jpg');
  });

  test('a listing without photos shows a placeholder but has nothing to edit', () {
    final listing = MaterialListing.fromJson(listingJson({'imageUrl': null, 'imageUrls': <String>[]}));

    expect(listing.photos.single, contains('placeholder'));
    expect(listing.uploadedPhotos, isEmpty);
  });

  test('older listings with only one photo field still show it', () {
    final listing = MaterialListing.fromJson(listingJson({'imageUrls': <String>[]}));

    expect(listing.photos, ['$server/uploads/material_listings/a.jpg']);
    expect(listing.uploadedPhotos, ['$server/uploads/material_listings/a.jpg']);
  });

  test('missing optional fields fall back to safe defaults', () {
    final listing = MaterialListing.fromJson({'id': 'l2', 'type': 0});

    expect(listing.title, 'Unknown Title');
    expect(listing.quantity, '0');
    expect(listing.isVerifiedSeller, isFalse);
    expect(listing.availability, isNull);
  });
}
