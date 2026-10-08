// Navigation - My Profile to the Business Hub.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:eco_loop/features/business_hub/domain/entities/business_profile.dart';
import 'package:eco_loop/features/business_hub/presentation/pages/business_hub_landing_page.dart';
import 'package:eco_loop/features/business_hub/presentation/pages/create_business_profile_page.dart';
import 'package:eco_loop/features/business_hub/presentation/providers/business_hub_providers.dart';
import 'package:eco_loop/features/profile/presentation/pages/profile_page.dart';
import 'package:eco_loop/features/profile/presentation/providers/profile_provider.dart';

import '../../helpers/fakes.dart';

const _business = BusinessProfile(
  id: 'b1', businessName: 'GreenCycle', businessType: 'Recycling Company', registrationNumber: 'PV-1',
  email: 'green@ecoloop.lk', phone: '0771234567', address: 'Colombo', isVerified: true, status: 'Verified',
  userId: 'me',
);

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  Future<void> pump(WidgetTester tester, List<BusinessProfile> businesses) async {
    tester.view.physicalSize = const Size(1080, 2600);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        profileNotifierProvider.overrideWith(FakeProfileNotifier.new),
        myBusinessProfilesProvider.overrideWith((ref) async => businesses),
      ],
      child: const MaterialApp(home: ProfilePage()),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('without a business, the button opens the verification request form', (tester) async {
    await pump(tester, const []);

    await tester.tap(find.text('Request Business Verification'));
    await tester.pumpAndSettle();

    expect(find.byType(CreateBusinessProfilePage), findsOneWidget);
  });

  testWidgets('with a business, the Business Hub button opens the hub', (tester) async {
    await pump(tester, const [_business]);

    expect(find.text('Request Business Verification'), findsNothing);
    await tester.tap(find.text('Business Hub'));
    await tester.pumpAndSettle();

    expect(find.byType(BusinessHubLandingPage), findsOneWidget);
  });
}
