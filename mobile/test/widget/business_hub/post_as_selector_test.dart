import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:eco_loop/features/business_hub/domain/entities/business_profile.dart';
import 'package:eco_loop/features/business_hub/presentation/providers/business_hub_providers.dart';
import 'package:eco_loop/features/business_hub/presentation/widgets/post_as_selector.dart';

BusinessProfile _business(String id, String name, {bool verified = false}) =>
    BusinessProfile(
      id: id,
      businessName: name,
      businessType: 'Recycling Company',
      registrationNumber: 'REG-$id',
      email: '$id@ecoloop.lk',
      phone: '0771234567',
      address: 'Colombo',
      isVerified: verified,
      status: verified ? 'Verified' : 'Unverified',
    );

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  Future<void> pump(
    WidgetTester tester,
    List<BusinessProfile> businesses,
    ValueChanged<String?> onChanged, {
    String? value,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          myBusinessProfilesProvider.overrideWith((ref) async => businesses),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: PostAsSelector(value: value, onChanged: onChanged),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders nothing for users without a business', (tester) async {
    await pump(tester, const [], (_) {});
    expect(find.text('Posting as'), findsNothing);
  });

  testWidgets('offers only verified businesses and explains pending ones',
      (tester) async {
    String? selected;
    await pump(
      tester,
      [
        _business('a', 'GreenCycle', verified: true),
        _business('b', 'PlastiCo'),
      ],
      (id) => selected = id,
    );

    expect(find.text('Posting as'), findsOneWidget);
    expect(find.textContaining('PlastiCo can be used after an admin verifies it'),
        findsOneWidget);

    await tester.tap(find.byType(DropdownButtonFormField<String?>));
    await tester.pumpAndSettle();
    expect(find.text('GreenCycle'), findsWidgets);
    expect(find.text('PlastiCo'), findsNothing);

    await tester.tap(find.text('GreenCycle').last);
    await tester.pumpAndSettle();
    expect(selected, 'a');
  });

  testWidgets('falls back to personal when the preselected business is not verified',
      (tester) async {
    String? selected = 'b';
    await pump(
      tester,
      [_business('b', 'PlastiCo')],
      (id) => selected = id,
      value: 'b',
    );
    expect(selected, isNull);
  });
}
