import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client_provider.dart';
import '../../data/business_repository.dart';
import '../../domain/entities/business_profile.dart';

final businessRepositoryProvider = Provider<BusinessRepository>((ref) {
  return BusinessRepository(apiClient: ref.watch(apiClientProvider));
});

/// Business Hub profiles owned by the signed-in account.
final myBusinessProfilesProvider =
    FutureProvider.autoDispose<List<BusinessProfile>>((ref) {
  return ref.watch(businessRepositoryProvider).getMyBusinessProfiles();
});
