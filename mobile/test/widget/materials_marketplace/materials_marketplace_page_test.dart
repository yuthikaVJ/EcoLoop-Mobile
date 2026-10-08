// Material marketplace - main screen
// (lib/features/materials_marketplace/presentation/pages/materials_marketplace_page.dart).
// Replaces Flutter's default starter test, which launched the whole app.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:eco_loop/features/ai_matching/presentation/matches_providers.dart';
import 'package:eco_loop/features/materials_marketplace/domain/entities/material_listing.dart';
import 'package:eco_loop/features/materials_marketplace/presentation/pages/materials_marketplace_page.dart';
import 'package:eco_loop/features/materials_marketplace/presentation/providers/material_listings_provider.dart';

MaterialListing _listing(String id, String title, {required bool iHave}) => MaterialListing(
      id: id,
      title: title,
      category: 'Plastics',
      quantity: '100',
      unit: 'Kgs',
      location: 'Colombo',
      price: 50,
      priceUnit: 'Kg',
      companyName: 'GreenCycle',
      isVerifiedSeller: true,
      isIHave: iHave,
      status: 0,
      datePosted: DateTime(2026, 10, 1),
    );

class _FakeListings extends MaterialListingsNotifier {
  @override
  Future<List<MaterialListing>> build() async => [
        _listing('h1', 'PET bottles on offer', iHave: true),
        _listing('n1', 'Need cardboard', iHave: false),
      ];
}

void main() {
  Future<void> pump(WidgetTester tester, {int pendingMatches = 0}) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        activeListingsNotifierProvider.overrideWith(_FakeListings.new),
        pendingMatchCountProvider.overrideWith((ref) => pendingMatches),
      ],
      child: const MaterialApp(home: MaterialsMarketplacePage()),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('shows the I Have / I Need switch and the search box', (tester) async {
    await pump(tester);

    expect(find.text('I Have'), findsOneWidget);
    expect(find.text('I Need'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Search materials, categories...'), findsOneWidget);
  });

  testWidgets('I Have lists offers; I Need lists requests', (tester) async {
    await pump(tester);
    expect(find.text('PET bottles on offer'), findsWidgets);
    expect(find.text('Need cardboard'), findsNothing);

    await tester.tap(find.text('I Need'));
    await tester.pumpAndSettle();
    expect(find.text('Need cardboard'), findsWidgets);
    expect(find.text('PET bottles on offer'), findsNothing);
  });

  testWidgets('the AI Matches button shows how many matches wait for a decision', (tester) async {
    await pump(tester, pendingMatches: 2);

    expect(find.byTooltip('AI Matches'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
  });
}
