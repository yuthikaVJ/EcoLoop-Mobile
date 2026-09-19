import 'package:eco_loop/features/transactions_delivery/domain/entities/transaction_models.dart';
import 'package:eco_loop/features/transactions_delivery/presentation/widgets/status_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('material transaction JSON includes delivery and status history', () {
    final item = MaterialTransactionDetails.fromJson({
      'id': 'transaction-id',
      'materialListingId': 'listing-id',
      'listingTitle': 'Recycled plastic',
      'buyer': 'Buyer',
      'seller': 'Seller',
      'buyerBusinessId': 'buyer-id',
      'sellerBusinessId': 'seller-id',
      'quantity': 2.5,
      'unit': 'Tons',
      'unitPrice': 100,
      'totalAmount': 250,
      'status': 0,
      'statusName': 'Pending',
      'deliveryMethod': 1,
      'createdAt': '2026-09-17T10:00:00Z',
      'delivery': {
        'id': 'delivery-id',
        'method': 1,
        'methodName': 'SellerDelivery',
        'location': 'Colombo',
        'createdAt': '2026-09-17T10:00:00Z',
      },
      'statusHistory': [
        {
          'status': 0,
          'statusName': 'Pending',
          'note': 'Transaction requested',
          'createdAt': '2026-09-17T10:00:00Z',
        }
      ],
    });

    expect(item.totalAmount, 250);
    expect(item.delivery?.method, DeliveryMethod.sellerDelivery);
    expect(item.delivery?.location, 'Colombo');
    expect(item.statusHistory.single.statusName, 'Pending');
  });

  testWidgets('cancelled status uses the shared status badge', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: StatusBadge(status: 'Cancelled'))));
    expect(find.text('Cancelled'), findsOneWidget);
  });
}
