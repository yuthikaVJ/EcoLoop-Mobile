// API integration - AI matching (lib/features/ai_matching/data/matches_repository.dart).
// The app only talks to the EcoLoop backend; the AI service is never called directly.
import 'package:flutter_test/flutter_test.dart';

import 'package:eco_loop/core/network/api_client.dart';
import 'package:eco_loop/features/ai_matching/data/matches_repository.dart';
import 'package:eco_loop/features/auth/data/repositories/auth_repository.dart';

import '../../helpers/fake_server.dart';

Map<String, dynamic> side(String id, String type) => {
      'id': id, 'type': type, 'title': 'PET', 'category': 'Plastics', 'quantity': '300', 'unit': 'Kgs',
      'location': 'Colombo', 'seller': 'GreenCycle', 'sellerIsVerified': true, 'ownerBusinessId': 'o-$id',
    };

void main() {
  late FakeServer server;
  late MatchesRepository repository;

  setUp(() {
    signIn();
    server = FakeServer();
    repository = MatchesRepository(ApiClient(AuthRepository()));
  });

  test('loads my suggestions', () async {
    server.json('GET', '/api/matches', [
      {'id': 's1', 'score': 0.9, 'reasons': ['Material matches'], 'warnings': [], 'myDecision': 'PENDING',
       'otherDecision': 'PENDING', 'myListing': side('m1', 'I_HAVE'), 'otherListing': side('o1', 'I_NEED')},
    ]);

    final matches = await server.run(repository.getMine);

    expect(matches.single.scorePercent, 90);
    expect(server.last('GET', '/api/matches').headers['Authorization'], 'Bearer access-1');
  });

  test('Connect returns the chat to open', () async {
    server.json('POST', '/api/matches/s1/connect',
        {'suggestionId': 's1', 'chatListingId': 'o1', 'otherBusinessId': 'biz-2'});

    final chat = await server.run(() => repository.connect('s1'));

    expect(chat.listingId, 'o1');
    expect(chat.otherBusinessId, 'biz-2');
  });

  test('Not interested and Find matches call their endpoints', () async {
    server.json('POST', '/api/matches/s1/dismiss', {}, status: 204);
    server.json('POST', '/api/matches/listings/l1/run', {'workflowId': 'w1', 'state': 'MATCHING'}, status: 202);

    await server.run(() async {
      await repository.dismiss('s1');
      await repository.findMatches('l1');
    });

    expect(server.requests.map((r) => r.url.path),
        containsAll(['/api/matches/s1/dismiss', '/api/matches/listings/l1/run']));
  });

  test('activity shows the latest check per post', () async {
    server.json('GET', '/api/matches/activity', [
      {'listingId': 'l1', 'title': 'PET', 'type': 'I_HAVE', 'state': 'SAFE_FAILURE', 'outcome': 'NO_MATCH',
       'reason': 'No other users have matching I NEED posts yet.', 'suggestionCount': 0},
    ]);

    final activity = await server.run(repository.getActivity);

    expect(activity.single.reason, startsWith('No other users'));
    expect(activity.single.isChecking, isFalse);
  });

  test('backend messages reach the user', () async {
    server.json('POST', '/api/matches/s1/connect', {'message': 'One of the posts is no longer active.'}, status: 409);

    final error = await server.run(() => repository.connect('s1')).then<Object?>((_) => null, onError: (e) => e);

    expect(error, isA<ApiException>()
        .having((e) => e.statusCode, 'status', 409)
        .having((e) => e.message, 'message', 'One of the posts is no longer active.'));
  });
}
