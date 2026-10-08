// Navigation - material marketplace: the screens a user reaches from the marketplace.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:eco_loop/features/ai_matching/presentation/matches_page.dart';
import 'package:eco_loop/features/ai_matching/presentation/matches_providers.dart';
import 'package:eco_loop/features/materials_marketplace/presentation/pages/add_material_page.dart';
import 'package:eco_loop/features/materials_marketplace/presentation/pages/material_details_page.dart';
import 'package:eco_loop/features/materials_marketplace/presentation/pages/materials_marketplace_page.dart';
import 'package:eco_loop/features/materials_marketplace/presentation/pages/my_listings_page.dart';
import 'package:eco_loop/features/materials_marketplace/presentation/providers/material_listings_provider.dart';
import 'package:eco_loop/features/business_hub/presentation/providers/business_hub_providers.dart';
import 'package:eco_loop/features/profile/presentation/providers/profile_provider.dart';

import '../../helpers/fakes.dart';

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        activeListingsNotifierProvider.overrideWith(
            () => FakeListingsNotifier([testListing(title: 'PET bottles on offer', businessId: 'someone-else')])),
        profileNotifierProvider.overrideWith(FakeProfileNotifier.new),
        myMatchesProvider.overrideWith((ref) async => const []),
        myMatchActivityProvider.overrideWith((ref) async => const []),
        myBusinessProfilesProvider.overrideWith((ref) async => const []),
      ],
      child: const MaterialApp(home: MaterialsMarketplacePage()),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('tapping a listing opens its details, and back returns', (tester) async {
    await pump(tester);

    await tester.tap(find.text('PET bottles on offer').first);
    await tester.pumpAndSettle();
    expect(find.byType(MaterialDetailsPage), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(MaterialDetailsPage), findsNothing);
    expect(find.byType(MaterialsMarketplacePage), findsOneWidget);
  });

  testWidgets('the sparkle button opens AI Matches', (tester) async {
    await pump(tester);

    await tester.tap(find.byTooltip('AI Matches'));
    await tester.pumpAndSettle();

    expect(find.byType(MatchesPage), findsOneWidget);
    expect(find.text('No matches yet'), findsOneWidget);
  });

  testWidgets('the list button opens My Listings', (tester) async {
    await pump(tester);

    await tester.tap(find.byTooltip('My Listings'));
    await tester.pumpAndSettle();

    expect(find.byType(MyListingsPage), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
  });

  testWidgets('the post button opens the add-listing form', (tester) async {
    await pump(tester);

    await tester.tap(find.byType(FloatingActionButton).first);
    await tester.pumpAndSettle();

    expect(find.byType(AddMaterialPage), findsOneWidget);
  });
}
