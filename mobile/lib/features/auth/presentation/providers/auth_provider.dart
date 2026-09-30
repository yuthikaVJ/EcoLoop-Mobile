import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

class AuthNotifier extends AsyncNotifier<bool> {
  late AuthRepository _repository;

  @override
  Future<bool> build() async {
    _repository = ref.watch(authRepositoryProvider);
    return _checkAuthStatus();
  }

  Future<bool> _checkAuthStatus() async {
    final token = await _repository.getSavedToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      await _repository.signInWithGoogle();
      final isLoggedIn = await _checkAuthStatus();
      state = AsyncValue.data(isLoggedIn);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      await _repository.signOut();
      state = const AsyncValue.data(false);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final authNotifierProvider = AsyncNotifierProvider<AuthNotifier, bool>(() {
  return AuthNotifier();
});
