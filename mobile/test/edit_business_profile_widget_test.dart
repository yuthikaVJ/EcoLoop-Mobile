import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eco_loop/features/business_hub/domain/entities/business_profile.dart';
import 'package:eco_loop/features/business_hub/presentation/pages/business_profile_details_page.dart';
import 'package:eco_loop/features/business_hub/presentation/pages/edit_business_profile_page.dart';

void main() {
  const testProfile = BusinessProfile(
    id: 'test-guid-1234',
    businessName: 'Lanka Green Upcycle',
    businessType: 'Recycling Company',
    registrationNumber: 'PV-88221',
    bio: 'Pioneering circular waste recycling across Western Province.',
    description: 'Specializing in converting post-consumer PET bottles into fiber.',
    email: 'info@lankagreen.lk',
    phone: '+94112345678',
    address: '12 Circular Way, Colombo 03',
    websiteUrl: 'https://lankagreen.lk',
    isVerified: true,
    status: 'Verified',
    userId: '11111111-1111-1111-1111-111111111111',
  );

  group('BusinessProfileDetailsPage Widget Tests', () {
    testWidgets('renders Facebook-style profile with cover, avatar, bio, and verified badge',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: BusinessProfileDetailsPage(
            profile: testProfile,
            currentUserId: '11111111-1111-1111-1111-111111111111',
          ),
        ),
      );

      // Verify business name is rendered
      expect(find.text('Lanka Green Upcycle'), findsWidgets);

      // Verify bio is rendered
      expect(
        find.text('Pioneering circular waste recycling across Western Province.'),
        findsOneWidget,
      );

      // Verify business type is rendered
      expect(find.text('Recycling Company'), findsOneWidget);

      // Verify verified badge is shown
      expect(find.byIcon(Icons.verified), findsOneWidget);

      // Verify Edit Profile button is present for the owner
      expect(find.text('Edit Profile'), findsOneWidget);

      // Verify contact details
      expect(find.text('info@lankagreen.lk'), findsOneWidget);
      expect(find.text('+94112345678'), findsOneWidget);
      expect(find.text('12 Circular Way, Colombo 03'), findsOneWidget);
    });
  });

  group('EditBusinessProfilePage Widget Tests', () {
    testWidgets('pre-populates form fields and shows Save button',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: EditBusinessProfilePage(
            profile: testProfile,
            currentUserId: '11111111-1111-1111-1111-111111111111',
          ),
        ),
      );

      // Verify pre-populated text
      expect(find.widgetWithText(TextFormField, 'Lanka Green Upcycle'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'info@lankagreen.lk'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, '+94112345678'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, '12 Circular Way, Colombo 03'), findsOneWidget);

      // Verify Save button in AppBar and Save Changes at bottom
      expect(find.text('Save'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);

      // Verify Media actions
      expect(find.text('Add Cover'), findsOneWidget);
      expect(find.text('Upload'), findsOneWidget);
    });

    testWidgets('shows validation error when required field is empty',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: EditBusinessProfilePage(
            profile: testProfile,
            currentUserId: '11111111-1111-1111-1111-111111111111',
          ),
        ),
      );

      // Clear the name field
      final nameField = find.widgetWithText(TextFormField, 'Lanka Green Upcycle');
      await tester.enterText(nameField, '');
      await tester.pump();

      // Tap Save
      await tester.tap(find.text('Save'));
      await tester.pump();

      // Verify error message is displayed
      expect(find.text('Business name is required'), findsOneWidget);
    });
  });
}
