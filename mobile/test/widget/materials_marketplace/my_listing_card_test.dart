// Material marketplace - My Listings card
// (lib/features/materials_marketplace/presentation/widgets/my_listing_card.dart).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:eco_loop/features/materials_marketplace/domain/entities/material_listing.dart';
import 'package:eco_loop/features/materials_marketplace/presentation/widgets/my_listing_card.dart';

final _listing = MaterialListing(
  id: 'l1',
  title: 'PET bottles',
  category: 'Plastics',
  quantity: '500',
  unit: 'Kgs',
  location: 'Colombo',
  price: 120,
  priceUnit: 'Kg',
  isVerifiedSeller: false,
  isIHave: true,
  status: 0,
  datePosted: DateTime(2026, 10, 1),
);

void main() {
  Future<List<String>> pump(WidgetTester tester, {required bool active, bool withMatches = true}) async {
    final taps = <String>[];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: MyListingCard(
          listing: _listing,
          isActive: active,
          onEdit: () => taps.add('edit'),
          onDelete: () => taps.add('delete'),
          onMarkSold: () => taps.add('sold'),
          onFindMatches: withMatches ? () => taps.add('matches') : null,
        ),
      ),
    ));
    return taps;
  }

  testWidgets('an active listing can be edited, deleted, sold or matched', (tester) async {
    final taps = await pump(tester, active: true);

    for (final label in ['Edit', 'Delete', 'Mark Sold', 'Find matches with EcoLoop AI']) {
      await tester.tap(find.text(label));
    }
    expect(taps, ['edit', 'delete', 'sold', 'matches']);
  });

  testWidgets('a completed listing can only be removed from history', (tester) async {
    final taps = await pump(tester, active: false);

    expect(find.text('Edit'), findsNothing);
    expect(find.text('Find matches with EcoLoop AI'), findsNothing);
    await tester.tap(find.text('Remove History'));
    expect(taps, ['delete']);
  });

  testWidgets('the AI strip is hidden when matching is not offered', (tester) async {
    await pump(tester, active: true, withMatches: false);
    expect(find.text('Find matches with EcoLoop AI'), findsNothing);
  });
}
