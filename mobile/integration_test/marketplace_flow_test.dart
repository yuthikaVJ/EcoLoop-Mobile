// End-to-end flows on a real device or emulator: the app's real screens,
// providers, repositories and ApiClient, with only the server replaced by a
// fake EcoLoop backend (so the test never changes real data).
//
// Run: flutter test integration_test        (an emulator or phone must be connected)
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:integration_test/integration_test.dart';

import 'package:eco_loop/core/network/api_client.dart';
import 'package:eco_loop/core/network/api_client_provider.dart';
import 'package:eco_loop/core/theme/app_theme.dart';
import 'package:eco_loop/features/auth/data/repositories/auth_repository.dart';
import 'package:eco_loop/features/materials_marketplace/presentation/pages/materials_marketplace_page.dart';

/// In-memory EcoLoop backend: listings, AI matches and their decisions.
class FakeEcoLoopBackend {
  final requests = <http.Request>[];
  final listings = <Map<String, dynamic>>[
    _listing('have-1', 'Clean PET bottles', type: 0, seller: 'GreenCycle'),
    _listing('need-1', 'Need cardboard bales', type: 1, seller: 'BoxCo'),
  ];
  final matches = <Map<String, dynamic>>[
    {
      'id': 's1',
      'score': 0.91,
      'reasons': ['Material type matches', 'Required quantity is available'],
      'warnings': [],
      'quantityCoverage': 1.0,
      'distanceKm': 25.0,
      'myDecision': 'PENDING',
      'otherDecision': 'PENDING',
      'myListing': _side('mine-1', 'I_NEED', 'My PET request'),
      'otherListing': _side('have-1', 'I_HAVE', 'Clean PET bottles'),
    },
  ];

  static Map<String, dynamic> _listing(String id, String title, {required int type, required String seller}) => {
        'id': id, 'businessId': 'other', 'title': title, 'category': type == 0 ? 'Plastics' : 'Paper',
        'description': 'Integration test listing', 'quantity': '500', 'unit': 'Kgs', 'location': 'Colombo',
        'price': 50, 'priceUnit': 'Kg', 'type': type, 'status': 0, 'seller': seller, 'sellerIsVerified': true,
        'createdAt': DateTime.now().toIso8601String(),
      };

  static Map<String, dynamic> _side(String id, String type, String title) => {
        'id': id, 'type': type, 'title': title, 'category': 'Plastics', 'quantity': '300', 'unit': 'Kgs',
        'location': 'Gampaha', 'seller': 'GreenCycle', 'sellerIsVerified': true, 'ownerBusinessId': 'o-$id',
      };

  http.Client client() => MockClient((request) async {
        requests.add(request);
        final path = request.url.path;
        http.Response json(Object body, [int status = 200]) =>
            http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json'});

        if (request.method == 'GET' && path == '/api/MaterialListings') return json({'items': listings});
        if (request.method == 'GET' && path == '/api/matches') return json(matches);
        if (request.method == 'GET' && path == '/api/matches/activity') return json([]);
        if (request.method == 'POST' && path == '/api/matches/s1/dismiss') {
          matches.clear();
          return http.Response('', 204);
        }
        return json({'message': 'Not available in this test'}, 404);
      });
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // The app's real ApiClient, repositories and providers, pointed at the fake
  // backend through Riverpod (the only override).
  Future<void> launch(WidgetTester tester, FakeEcoLoopBackend backend, Future<void> Function() flow) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        apiClientProvider.overrideWithValue(ApiClient(AuthRepository(), client: backend.client())),
      ],
      child: MaterialApp(theme: AppTheme.lightTheme, home: const MaterialsMarketplacePage()),
    ));
    // The marketplace shows a skeleton for ~1.5 s before the listings.
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    await flow();
  }

  testWidgets('browse the marketplace: I Have offers, then I Need requests', (tester) async {
    final backend = FakeEcoLoopBackend();
    await launch(tester, backend, () async {
      expect(find.text('Clean PET bottles'), findsWidgets);
      expect(find.text('Need cardboard bales'), findsNothing);

      await tester.tap(find.text('I Need'));
      await tester.pumpAndSettle();
      expect(find.text('Need cardboard bales'), findsWidgets);
      expect(backend.requests.any((r) => r.url.path == '/api/MaterialListings'), isTrue);
    });
  });

  testWidgets('review an AI match and mark it Not interested', (tester) async {
    final backend = FakeEcoLoopBackend();
    await launch(tester, backend, () async {
      await tester.tap(find.byTooltip('AI Matches'));
      await tester.pumpAndSettle();

      expect(find.text('91% match'), findsOneWidget);
      expect(find.text('Material type matches'), findsOneWidget);
      expect(find.textContaining('nothing happens until you choose Connect'), findsOneWidget);

      await tester.tap(find.text('Not interested'));
      await tester.pumpAndSettle();

      expect(backend.requests.where((r) => r.url.path == '/api/matches/s1/dismiss'), hasLength(1));
      expect(find.text('No matches yet'), findsOneWidget);
    });
  });
}
