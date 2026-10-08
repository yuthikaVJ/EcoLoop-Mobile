// Material marketplace - listing cards
// (lib/features/materials_marketplace/presentation/widgets/): every card shows
// the seller, with the blue verified badge only for verified businesses.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:eco_loop/features/materials_marketplace/domain/entities/material_listing.dart';
import 'package:eco_loop/features/materials_marketplace/presentation/widgets/featured_material_card.dart';
import 'package:eco_loop/features/materials_marketplace/presentation/widgets/grid_material_card.dart';
import 'package:eco_loop/features/materials_marketplace/presentation/widgets/material_list_card.dart';
import 'package:eco_loop/shared/widgets/seller_name.dart';

MaterialListing listing({bool verified = true}) => MaterialListing(
      id: 'l1',
      title: 'PET bottles',
      category: 'Plastics',
      quantity: '500',
      unit: 'Kgs',
      location: 'Colombo',
      price: 120,
      priceUnit: 'Kg',
      companyName: 'GreenCycle',
      isVerifiedSeller: verified,
      isIHave: true,
      status: 0,
      datePosted: DateTime(2026, 10, 1),
    );

Future<void> pump(WidgetTester tester, Widget card) => tester.pumpWidget(
      MaterialApp(home: Scaffold(body: SingleChildScrollView(child: SizedBox(width: 400, child: card)))),
    );

void main() {
  final cards = <String, Widget Function(MaterialListing, VoidCallback)>{
    'list card': (l, tap) => MaterialListCard(listing: l, heroTag: 'h', onTap: tap),
    'grid card': (l, tap) => SizedBox(height: 260, child: GridMaterialCard(listing: l, onTap: tap)),
    'featured card': (l, tap) => SizedBox(height: 260, child: FeaturedMaterialCard(listing: l, onTap: tap)),
  };

  for (final entry in cards.entries) {
    group(entry.key, () {
      testWidgets('shows the title, seller and verified badge', (tester) async {
        await pump(tester, entry.value(listing(), () {}));

        expect(find.text('PET bottles'), findsOneWidget);
        expect(find.text('GreenCycle'), findsOneWidget);
        expect(find.byType(VerifiedBadge), findsOneWidget);
      });

      testWidgets('shows no badge for an unverified seller', (tester) async {
        await pump(tester, entry.value(listing(verified: false), () {}));

        expect(find.text('GreenCycle'), findsOneWidget);
        expect(find.byType(VerifiedBadge), findsNothing);
      });

      testWidgets('tapping opens the listing', (tester) async {
        var tapped = 0;
        await pump(tester, entry.value(listing(), () => tapped++));

        await tester.tap(find.text('PET bottles'));
        expect(tapped, 1);
      });
    });
  }
}
