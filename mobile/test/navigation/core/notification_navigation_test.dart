// Navigation - tapping a push notification opens the screen it is about
// (lib/core/notifications/notification_router.dart).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:eco_loop/core/notifications/notification_router.dart';
import 'package:eco_loop/features/ai_matching/presentation/matches_page.dart';
import 'package:eco_loop/features/ai_matching/presentation/matches_providers.dart';
import 'package:eco_loop/features/business_hub/presentation/pages/business_hub_landing_page.dart';
import 'package:eco_loop/features/business_hub/presentation/providers/business_hub_providers.dart';
import 'package:eco_loop/features/materials_marketplace/presentation/pages/inbox_page.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        myMatchesProvider.overrideWith((ref) async => const []),
        myMatchActivityProvider.overrideWith((ref) async => const []),
        myBusinessProfilesProvider.overrideWith((ref) async => const []),
      ],
      child: MaterialApp(navigatorKey: appNavigatorKey, home: const Scaffold(body: Text('home'))),
    ));
  }

  testWidgets('a match notification opens AI Matches', (tester) async {
    await pump(tester);

    await NotificationRouter.open({'type': 'material_match', 'suggestionId': 's1'});
    await tester.pumpAndSettle();

    expect(find.byType(MatchesPage), findsOneWidget);
  });

  testWidgets('a verification result opens the Business Hub', (tester) async {
    await pump(tester);

    await NotificationRouter.open({'type': 'business_verification', 'businessId': 'b1'});
    await tester.pumpAndSettle();

    expect(find.byType(BusinessHubLandingPage), findsOneWidget);
  });

  testWidgets('a chat message without its sender opens the inbox', (tester) async {
    await pump(tester);

    await NotificationRouter.open({'type': 'chat_message', 'listingId': 'l1'});
    await tester.pumpAndSettle();

    expect(find.byType(InboxPage), findsOneWidget);
  });

  testWidgets('an unknown notification type stays on the current screen', (tester) async {
    await pump(tester);

    await NotificationRouter.open({'type': 'something_else'});
    await tester.pumpAndSettle();

    expect(find.text('home'), findsOneWidget);
  });
}
