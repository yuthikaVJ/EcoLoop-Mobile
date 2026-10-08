// Form validation - Edit Material Listing
// (lib/features/materials_marketplace/presentation/pages/edit_material_page.dart).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:eco_loop/features/materials_marketplace/presentation/pages/edit_material_page.dart';
import 'package:eco_loop/features/materials_marketplace/presentation/providers/material_listings_provider.dart';

import '../../helpers/fakes.dart';

void main() {
  late FakeListingsNotifier listings;

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2600);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);
    listings = FakeListingsNotifier();
    await tester.pumpWidget(ProviderScope(
      overrides: [activeListingsNotifierProvider.overrideWith(() => listings)],
      child: MaterialApp(home: EditMaterialPage(listing: testListing())),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('the form starts filled with the listing', (tester) async {
    await pump(tester);
    expect(find.widgetWithText(TextFormField, 'PET bottles'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Colombo'), findsOneWidget);
  });

  testWidgets('clearing a required field blocks the update', (tester) async {
    await pump(tester);

    await tester.enterText(find.widgetWithText(TextFormField, 'PET bottles'), '');
    await tester.tap(find.text('Update Listing'));
    await tester.pumpAndSettle();

    expect(find.text('Please enter a name'), findsOneWidget);
    expect(listings.updated, isEmpty);
  });

  testWidgets('a valid change is saved with the details and kept photos', (tester) async {
    await pump(tester);

    await tester.enterText(find.widgetWithText(TextFormField, 'PET bottles'), 'Clear PET bottles');
    await tester.tap(find.text('Update Listing'));
    await tester.pumpAndSettle();

    final saved = listings.updated.single;
    expect(saved['title'], 'Clear PET bottles');
    expect(saved['keepImageUrls'], isEmpty); // the test listing has no uploaded photos
  });
}
