import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:eco_loop/features/ai_matching/domain/match_suggestion.dart';
import 'package:eco_loop/features/ai_matching/presentation/matches_page.dart';
import 'package:eco_loop/features/ai_matching/presentation/matches_providers.dart';
import 'package:eco_loop/shared/widgets/seller_name.dart';

MatchSuggestion _suggestion({bool connected = false}) => MatchSuggestion.fromJson({
      'id': 's1',
      'score': 0.91,
      'reasons': ['Material type matches', 'Required quantity is available'],
      'warnings': ['Distance between the locations could not be determined.'],
      'quantityCoverage': 1.0,
      'distanceKm': null,
      'myDecision': connected ? 'CONNECTED' : 'PENDING',
      'otherDecision': 'PENDING',
      'myListing': {
        'id': 'm1', 'type': 'I_HAVE', 'title': '500 kg PET bottles', 'category': 'Plastics',
        'quantity': '500', 'unit': 'Kgs', 'location': 'Colombo', 'ownerBusinessId': 'me',
      },
      'otherListing': {
        'id': 'o1', 'type': 'I_NEED', 'title': 'Need PET bottles', 'category': 'Plastics',
        'quantity': '300', 'unit': 'Kgs', 'location': 'Gampaha', 'seller': 'GreenCycle',
        'sellerIsVerified': true, 'ownerBusinessId': 'them',
      },
    });

void main() {
  Future<void> pump(WidgetTester tester, List<MatchSuggestion> items,
      {List<MatchActivity> activity = const []}) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        myMatchesProvider.overrideWith((ref) async => items),
        myMatchActivityProvider.overrideWith((ref) async => activity),
      ],
      child: const MaterialApp(home: MatchesPage()),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('shows why the AI suggested a match and leaves the decision to the user', (tester) async {
    await pump(tester, [_suggestion()]);

    expect(find.textContaining('nothing happens until you choose Connect'), findsOneWidget);
    expect(find.text('Need PET bottles'), findsOneWidget);
    expect(find.text('300 Kgs · Gampaha'), findsOneWidget);
    expect(find.text('91% match'), findsOneWidget);
    expect(find.text('Material type matches'), findsOneWidget);
    expect(find.text('Distance between the locations could not be determined.'), findsOneWidget);
    expect(find.byType(VerifiedBadge), findsOneWidget);
    expect(find.text('Not interested'), findsOneWidget);
    expect(find.text('Connect'), findsOneWidget);
  });

  testWidgets('connected matches offer the chat instead of the decision buttons', (tester) async {
    await pump(tester, [_suggestion(connected: true)]);
    expect(find.text('Connected'), findsOneWidget);
    expect(find.text('Open chat'), findsOneWidget);
    expect(find.text('Not interested'), findsNothing);
  });

  testWidgets('explains why there are no matches, per post', (tester) async {
    await pump(tester, [], activity: const [
      MatchActivity(
        listingId: 'l1', title: 'Old Circuits Boards', isIHave: true, state: 'SAFE_FAILURE', outcome: 'NO_MATCH',
        reason: 'No other users have matching I NEED posts yet.',
      ),
      MatchActivity(listingId: 'l2', title: 'GTX 850 cards', isIHave: true),
    ]);
    expect(find.text('No matches yet'), findsOneWidget);
    expect(find.textContaining('Your own posts are never matched'), findsOneWidget);
    expect(find.text('I HAVE · Old Circuits Boards'), findsOneWidget);
    expect(find.text('No other users have matching I NEED posts yet.'), findsOneWidget);
    expect(find.text('No match yet'), findsOneWidget);
    expect(find.text('Not checked yet'), findsOneWidget);
    expect(find.text('Check again'), findsOneWidget);
    expect(find.text('Find matches'), findsOneWidget);
    expect(find.byIcon(Icons.search_off), findsNothing);
  });

  testWidgets('groups matches under my post and does not list that post twice', (tester) async {
    await pump(tester, [_suggestion()], activity: const [
      MatchActivity(listingId: 'm1', title: '500 kg PET bottles', isIHave: true, state: 'USER_APPROVAL',
          outcome: 'MATCHES', suggestionCount: 1),
      MatchActivity(listingId: 'l2', title: 'GTX 850 cards', isIHave: true, state: 'SAFE_FAILURE', outcome: 'NO_MATCH'),
    ]);
    expect(find.text('1 match'), findsOneWidget);
    expect(find.textContaining('For your I HAVE post: '), findsOneWidget);
    expect(find.textContaining('500 kg PET bottles'), findsOneWidget); // header only, not repeated below
    expect(find.text('Your other posts'), findsOneWidget);
    expect(find.text('I HAVE · GTX 850 cards'), findsOneWidget);
  });
}
