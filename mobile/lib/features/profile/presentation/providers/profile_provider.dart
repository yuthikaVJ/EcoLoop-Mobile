import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client_provider.dart';
import '../../domain/entities/account_profile.dart';
import '../../data/repositories/profile_repository.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ProfileRepository(apiClient);
});

class ProfileNotifier extends AsyncNotifier<AccountProfile> {
  late ProfileRepository _repository;

  @override
  Future<AccountProfile> build() async {
    _repository = ref.watch(profileRepositoryProvider);
    return _repository.getProfile();
  }

  Future<void> updateProfile(AccountProfile updatedProfile) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.updateProfile(updatedProfile);
      state = AsyncValue.data(result);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final profileNotifierProvider = AsyncNotifierProvider<ProfileNotifier, AccountProfile>(() {
  return ProfileNotifier();
});
