// Shared widgets - seller name and verified badge
// (lib/shared/widgets/seller_name.dart).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:eco_loop/shared/widgets/seller_name.dart';

Future<void> pump(WidgetTester tester, Widget child) =>
    tester.pumpWidget(MaterialApp(home: Scaffold(body: Center(child: SizedBox(width: 300, child: child)))));

void main() {
  testWidgets('a verified seller gets the blue badge with a tooltip', (tester) async {
    await pump(tester, const SellerName(name: 'GreenCycle', verified: true));

    expect(find.text('GreenCycle'), findsOneWidget);
    final icon = tester.widget<Icon>(find.byIcon(Icons.verified));
    expect(icon.color, verifiedBlue);
    expect(find.byTooltip('Verified business'), findsOneWidget);
  });

  testWidgets('an unverified seller has no badge', (tester) async {
    await pump(tester, const SellerName(name: 'GreenCycle', verified: false));
    expect(find.byType(VerifiedBadge), findsNothing);
  });

  testWidgets('a missing name shows "Unknown seller"', (tester) async {
    await pump(tester, const SellerName(name: '  ', verified: false));
    expect(find.text('Unknown seller'), findsOneWidget);
  });

  testWidgets('a long name is shortened but the badge stays visible', (tester) async {
    await pump(tester, SellerName(name: 'Very ' * 40, verified: true));
    expect(find.byType(VerifiedBadge), findsOneWidget);
    expect(tester.takeException(), isNull); // no overflow
  });

  testWidgets('seller tile on detail pages explains the verification', (tester) async {
    await pump(tester, const SellerTile(name: 'GreenCycle', verified: true));
    expect(find.text('Verified business on EcoLoop'), findsOneWidget);
    expect(find.text('G'), findsOneWidget); // initial while there is no logo

    await pump(tester, const SellerTile(name: 'GreenCycle', verified: false));
    expect(find.text('Not verified yet'), findsOneWidget);
  });
}
