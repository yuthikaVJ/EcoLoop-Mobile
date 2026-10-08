// Form validation - Add Material Listing
// (lib/features/materials_marketplace/presentation/pages/add_material_page.dart).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:eco_loop/features/business_hub/presentation/providers/business_hub_providers.dart';
import 'package:eco_loop/features/materials_marketplace/presentation/pages/add_material_page.dart';
import 'package:eco_loop/features/materials_marketplace/presentation/providers/material_listings_provider.dart';

import '../../helpers/fakes.dart';

void main() {
  late FakeListingsNotifier listings;

  Future<void> pump(WidgetTester tester, {bool iHave = true}) async {
    tester.view.physicalSize = const Size(1080, 2600);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);
    listings = FakeListingsNotifier();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        activeListingsNotifierProvider.overrideWith(() => listings),
        myBusinessProfilesProvider.overrideWith((ref) async => const []),
      ],
      child: MaterialApp(home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => AddMaterialPage(initialIsIHave: iHave))),
              child: const Text('open'),
            ),
          ),
        ),
      )),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Future<void> submit(WidgetTester tester) async {
    await tester.tap(find.text('Post Listing'));
    await tester.pumpAndSettle();
  }

  Finder field(String hint) => find.widgetWithText(TextFormField, hint);

  testWidgets('an empty form shows every required-field error and is not posted', (tester) async {
    await pump(tester);
    await submit(tester);

    expect(find.text('Please enter a name'), findsOneWidget);
    expect(find.text('Please select a category'), findsOneWidget);
    expect(find.text('Required'), findsNWidgets(3)); // quantity, price, location
    expect(listings.added, isEmpty);
  });

  testWidgets('an I NEED request does not ask for a price', (tester) async {
    await pump(tester, iHave: false);
    await submit(tester);

    expect(find.text('Required'), findsNWidgets(2)); // quantity, location
  });

  testWidgets('a complete form is posted with the entered details', (tester) async {
    await pump(tester);

    await tester.enterText(field('e.g., Mixed High-Density Polyethylene'), 'PET bottles');
    await tester.tap(find.text('Select Category'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Plastics').last);
    await tester.pumpAndSettle();
    final textFields = find.byType(TextFormField);
    await tester.enterText(textFields.at(2), '500'); // quantity
    await tester.enterText(field('0.00'), '120');
    await tester.enterText(field('Pickup address'), 'Colombo 07');
    await tester.ensureVisible(find.text('Immediately'));
    await tester.tap(find.text('Immediately'));
    await submit(tester);

    expect(find.text('Please enter a name'), findsNothing);
    final posted = listings.added.single;
    expect(posted['title'], 'PET bottles');
    expect(posted['category'], 'Plastics');
    expect(posted['quantity'], '500');
    expect(posted['price'], 120.0);
    expect(posted['location'], 'Colombo 07');
    expect(posted['type'], 0);
    expect(posted['availability'], 'Immediately');
    expect(posted.containsKey('postedAsBusinessId'), isFalse); // personal post
  });
}
