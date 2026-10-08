// AI matching - data models (lib/features/ai_matching/domain/match_suggestion.dart).
import 'package:flutter_test/flutter_test.dart';

import 'package:eco_loop/core/config/app_config.dart';
import 'package:eco_loop/features/ai_matching/domain/match_suggestion.dart';

Map<String, dynamic> side(String id, String type, {String? imageUrl}) => {
      'id': id,
      'type': type,
      'title': 'PET bottles',
      'category': 'Plastics',
      'quantity': '300',
      'unit': 'Kgs',
      'location': 'Gampaha',
      'imageUrl': imageUrl,
      'seller': 'GreenCycle',
      'sellerIsVerified': true,
      'ownerBusinessId': 'owner-$id',
    };

void main() {
  test('reads a suggestion with both posts', () {
    final match = MatchSuggestion.fromJson({
      'id': 's1',
      'score': 0.914,
      'reasons': ['Material type matches'],
      'warnings': ['Covers 60% of the requested quantity.'],
      'quantityCoverage': 0.6,
      'distanceKm': 25.4,
      'myDecision': 'PENDING',
      'otherDecision': 'CONNECTED',
      'myListing': side('m1', 'I_HAVE'),
      'otherListing': side('o1', 'I_NEED', imageUrl: '/uploads/material_listings/a.jpg'),
    });

    expect(match.scorePercent, 91);
    expect(match.isConnected, isFalse);
    expect(match.reasons.single, 'Material type matches');
    expect(match.quantityCoverage, 0.6);
    expect(match.myListing.typeLabel, 'I HAVE');
    expect(match.otherListing.typeLabel, 'I NEED');
    expect(match.otherListing.amount, '300 Kgs');
    expect(match.otherListing.sellerIsVerified, isTrue);
    expect(match.otherListing.imageUrl, '${AppConfig.serverUrl}/uploads/material_listings/a.jpg');
  });

  test('my Connect decision marks the suggestion as connected', () {
    final match = MatchSuggestion.fromJson({
      'id': 's1', 'score': 0.8, 'reasons': [], 'warnings': [],
      'myDecision': 'CONNECTED', 'otherDecision': 'PENDING',
      'myListing': side('m1', 'I_NEED'), 'otherListing': side('o1', 'I_HAVE'),
    });
    expect(match.isConnected, isTrue);
  });

  test('a post is "checking" until its workflow reaches a final state', () {
    MatchActivity activity(String? state) =>
        MatchActivity.fromJson({'listingId': 'l1', 'title': 'PET', 'type': 'I_HAVE', 'state': state});

    for (final running in ['MATCHING', 'ANALYZING', 'CANDIDATES_FOUND', 'VALIDATING', 'MATCH_READY']) {
      expect(activity(running).isChecking, isTrue, reason: running);
    }
    for (final done in ['USER_APPROVAL', 'CONNECTED', 'SAFE_FAILURE']) {
      expect(activity(done).isChecking, isFalse, reason: done);
    }
    expect(activity(null).isChecking, isFalse); // never checked
  });

  test('workflow status reports whether a run is still in progress', () {
    expect(MatchWorkflowStatus.fromJson({'state': 'ANALYZING'}).isRunning, isTrue);
    expect(MatchWorkflowStatus.fromJson({'state': 'SAFE_FAILURE', 'outcome': 'NO_MATCH'}).isRunning, isFalse);
  });
}
