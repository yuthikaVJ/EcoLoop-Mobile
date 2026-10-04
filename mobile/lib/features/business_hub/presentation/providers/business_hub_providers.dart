import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_client_provider.dart';
import '../../data/business_repository.dart';
import '../../domain/entities/business_profile.dart';

final businessRepositoryProvider = Provider<BusinessRepository>((ref) {
  return BusinessRepository(apiClient: ref.watch(apiClientProvider));
});

/// Riverpod retries failed providers for ~20 s by default. An HTTP error
/// answer (404, 403...) will not change on retry, so fail at once; retry a
/// network failure twice.
Duration? _retryNetworkErrorsOnly(int retryCount, Object error) {
  if (error is ApiException || retryCount >= 2) return null;
  return const Duration(seconds: 1);
}

/// Business Hub profiles owned by the signed-in account.
final myBusinessProfilesProvider =
    FutureProvider.autoDispose<List<BusinessProfile>>(
  (ref) => ref.watch(businessRepositoryProvider).getMyBusinessProfiles(),
  retry: _retryNetworkErrorsOnly,
);
