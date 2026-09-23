import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:eco_loop/core/network/api_client.dart';
import 'package:eco_loop/core/theme/app_theme.dart';
import 'package:eco_loop/features/business_hub/data/business_profile_session.dart';
import 'package:eco_loop/features/business_hub/domain/entities/business_profile.dart';
import 'package:eco_loop/features/business_hub/presentation/pages/business_hub_landing_page.dart';
import 'package:eco_loop/features/business_hub/presentation/widgets/business_profile_selection_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: child,
    );
  }

  testWidgets(
      'BusinessHubLandingPage displays onboarding card and no Directory tab',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      buildTestableWidget(const BusinessHubLandingPage()),
    );
    await tester.pump();

    // Verify Title & Subtitle
    expect(find.text('Business Hub'), findsOneWidget);
    expect(
      find.text('Build a greener tomorrow with your business'),
      findsOneWidget,
    );

    // Verify Directory Tab is REMOVED
    expect(find.textContaining('Directory'), findsNothing);
    expect(find.byType(TabBar), findsNothing);

    // Verify Card Contents
    expect(find.text('Join EcoLoop Business Hub'), findsOneWidget);
    expect(find.text('Circular Marketplace Access'), findsOneWidget);
    expect(find.text('Sustainable Product Store'), findsOneWidget);
    expect(find.text('eROC Business Verification'), findsOneWidget);

    // Verify Both Buttons are present
    expect(find.text('Create Business Profile'), findsOneWidget);
    expect(find.text('Sign into Business Profile'), findsOneWidget);
    expect(find.byIcon(Icons.switch_account_outlined), findsOneWidget);
  });

  testWidgets(
      'Tapping Sign into Business Profile opens the selection dialog',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      buildTestableWidget(const BusinessHubLandingPage()),
    );
    await tester.pump();

    final signInBtn = find.text('Sign into Business Profile');
    expect(signInBtn, findsOneWidget);

    await tester.ensureVisible(signInBtn);
    await tester.tap(signInBtn);
    await tester.pumpAndSettle();

    // Verify dialog header is visible
    expect(find.text('Select Business Profile'), findsOneWidget);
    expect(find.byIcon(Icons.close), findsOneWidget);
  });

  testWidgets(
      'BusinessProfileSelectionDialog displays profiles and allows selection',
      (WidgetTester tester) async {
    final mockProfile = BusinessProfile(
      id: 'test-business-id-123',
      businessName: 'Eco Plastic Solutions',
      businessType: 'Recycling Company',
      registrationNumber: 'REG-12345',
      email: 'ecoplastic@test.lk',
      phone: '0771234567',
      address: 'Colombo, Sri Lanka',
      isVerified: true,
      status: 'Verified',
      userId: defaultCurrentUserId,
    );

    await tester.pumpWidget(
      buildTestableWidget(
        Scaffold(
          body: BusinessProfileSelectionDialog(
            currentUserId: defaultCurrentUserId,
          ),
        ),
      ),
    );

    // Initial state shows loading
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  test('BusinessProfileSession saves and clears active profile', () async {
    final session = BusinessProfileSession();
    final profile = BusinessProfile(
      id: '123',
      businessName: 'Green Enterprise',
      businessType: 'Eco Manufacturer',
      registrationNumber: 'REG-001',
      email: 'contact@green.lk',
      phone: '0112345678',
      address: 'Kandy',
      isVerified: true,
      status: 'Verified',
    );

    await session.setActiveProfile(profile);
    expect(session.currentProfile?.businessName, 'Green Enterprise');
    expect(session.activeProfileNotifier.value?.id, '123');
    expect(session.hasActiveProfile, isTrue);
    expect(session.activeBusinessName, 'Green Enterprise');

    await session.clearActiveProfile();
    expect(session.currentProfile, isNull);
    expect(session.activeProfileNotifier.value, isNull);
    expect(session.hasActiveProfile, isFalse);
  });

  testWidgets(
      'Profile tab displays active business profile with banner and posts when signed in',
      (WidgetTester tester) async {
    final session = BusinessProfileSession();
    final profile = BusinessProfile(
      id: 'active-business-id',
      businessName: 'GreenCycle',
      businessType: 'Eco Manufacturer',
      registrationNumber: 'GC-12345',
      bio: 'Leading circular economy recycling partner.',
      email: 'greencycle@ecoloop.lk',
      phone: '0771234567',
      address: 'Colombo, Sri Lanka',
      isVerified: true,
      status: 'Verified',
      userId: defaultCurrentUserId,
    );

    await session.setActiveProfile(profile);

    await tester.pumpWidget(
      buildTestableWidget(const BusinessHubLandingPage()),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify Active Profile Banner
    expect(find.text('ACTIVE BUSINESS PROFILE'), findsOneWidget);
    expect(find.text('Acting as GreenCycle'), findsOneWidget);

    // Verify Profile Information is displayed
    expect(find.text('GreenCycle'), findsWidgets);
    expect(find.text('Eco Manufacturer'), findsWidgets);
    expect(find.text('Posts'), findsOneWidget);

    // Verify Posts for GreenCycle are displayed
    expect(find.text('I HAVE 500kg PET bottles'), findsOneWidget);
    expect(find.text('I NEED cardboard materials'), findsOneWidget);

    // Clean up session
    await session.clearActiveProfile();
  });

  testWidgets(
      'Signing out of active business profile returns to Business Hub onboarding',
      (WidgetTester tester) async {
    final session = BusinessProfileSession();
    final profile = BusinessProfile(
      id: 'signout-business-id',
      businessName: 'CleanEarth Co',
      businessType: 'Recycling Company',
      registrationNumber: 'CE-99999',
      email: 'cleanearth@ecoloop.lk',
      phone: '0779999999',
      address: 'Galle, Sri Lanka',
      isVerified: false,
      status: 'Unverified',
      userId: defaultCurrentUserId,
    );

    // Sign into business profile
    await session.setActiveProfile(profile);

    await tester.pumpWidget(
      buildTestableWidget(const BusinessHubLandingPage()),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Acting as CleanEarth Co'), findsOneWidget);

    // Sign out of business profile
    await session.clearActiveProfile();
    await tester.pumpAndSettle();

    // Verify returning to Business Hub landing screen
    expect(find.text('Join EcoLoop Business Hub'), findsOneWidget);
    expect(find.text('Sign into Business Profile'), findsOneWidget);
    expect(find.text('Acting as CleanEarth Co'), findsNothing);
  });
}
