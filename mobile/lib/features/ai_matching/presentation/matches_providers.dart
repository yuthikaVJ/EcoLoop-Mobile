import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_client_provider.dart';
import '../data/matches_repository.dart';
import '../domain/match_suggestion.dart';

final matchesRepositoryProvider = Provider<MatchesRepository>(
  (ref) => MatchesRepository(ref.watch(apiClientProvider)),
);

// HTTP error answers won't change on retry; only retry network failures, briefly.
Duration? _retryNetworkOnly(int count, Object error) =>
    error is ApiException || count >= 2 ? null : const Duration(seconds: 1);

/// AI match suggestions for the signed-in account.
final myMatchesProvider = FutureProvider.autoDispose<List<MatchSuggestion>>(
  (ref) => ref.watch(matchesRepositoryProvider).getMine(),
  retry: _retryNetworkOnly,
);

/// Matches still waiting for my decision (for the badge on the marketplace).
final pendingMatchCountProvider = Provider.autoDispose<int>((ref) {
  final matches = ref.watch(myMatchesProvider).value ?? const [];
  return matches.where((m) => !m.isConnected).length;
});

/// Latest AI check for each of my active posts.
final myMatchActivityProvider = FutureProvider.autoDispose<List<MatchActivity>>(
  (ref) => ref.watch(matchesRepositoryProvider).getActivity(),
  retry: _retryNetworkOnly,
);
