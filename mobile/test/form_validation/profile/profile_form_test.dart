// Form validation - My Profile (lib/features/profile/presentation/pages/profile_page.dart).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:eco_loop/features/business_hub/presentation/providers/business_hub_providers.dart';
import 'package:eco_loop/features/profile/presentation/pages/profile_page.dart';
import 'package:eco_loop/features/profile/presentation/providers/profile_provider.dart';

import '../../helpers/fakes.dart';

void main() {
  late FakeProfileNotifier profile;

  Future<void> pumpEditing(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2600);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);
    profile = FakeProfileNotifier();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        profileNotifierProvider.overrideWith(() => profile),
        myBusinessProfilesProvider.overrideWith((ref) async => const []),
      ],
      child: const MaterialApp(home: ProfilePage()),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.edit));
    await tester.pumpAndSettle();
  }

  Finder field(String label) => find.widgetWithText(TextFormField, label);

  Future<void> save(WidgetTester tester) async {
    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();
  }

  testWidgets('fields are read-only until Edit is tapped', (tester) async {
    await pumpEditing(tester);
    expect(tester.widget<TextFormField>(field('Full Name')).enabled, isTrue);
    expect(find.text('Save Changes'), findsOneWidget);
  });

  testWidgets('the full name is required', (tester) async {
    await pumpEditing(tester);

    await tester.enterText(field('Full Name'), '   ');
    await save(tester);

    expect(find.text('Required'), findsOneWidget);
    expect(profile.saved, isEmpty);
  });

  for (final bad in ['077123', '07712345678', '07712abcde']) {
    testWidgets('mobile number "$bad" is rejected', (tester) async {
      await pumpEditing(tester);

      await tester.enterText(field('Mobile Number'), bad);
      await save(tester);

      expect(find.text('Mobile number must be exactly 10 digits'), findsOneWidget);
      expect(profile.saved, isEmpty);
    });
  }

  testWidgets('an empty mobile number is allowed (it is optional)', (tester) async {
    await pumpEditing(tester);

    await tester.enterText(field('Mobile Number'), '');
    await save(tester);

    expect(profile.saved.single.phoneNumber, isEmpty);
  });

  testWidgets('valid details are saved, trimmed', (tester) async {
    await pumpEditing(tester);

    await tester.enterText(field('Full Name'), '  Haritha Geemal ');
    await tester.enterText(field('Mobile Number'), '0712345678');
    await tester.enterText(field('Address'), ' Kandy ');
    await save(tester);

    final saved = profile.saved.single;
    expect((saved.businessName, saved.phoneNumber, saved.address), ('Haritha Geemal', '0712345678', 'Kandy'));
    expect(find.text('Profile updated successfully!'), findsOneWidget);
  });
}
